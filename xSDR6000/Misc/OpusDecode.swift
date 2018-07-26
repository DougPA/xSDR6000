//
//  OpusDecode.swift
//  xSDR6000
//
//  Created by Douglas Adams on 2/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation
import xLib6000
import OpusOSX
import Accelerate
import AVFoundation


class OpusDecode                            : NSObject, StreamHandler {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kSampleRate                    : Float = 24_000                 // Sample Rate (samples/second)
  static let kNumberOfChannels              = 2                              // Right & Left channels
  static let kSampleCount                   = Int(kSampleRate / 100.0 )      // Number of input samples in 10 ms

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _decoder                      : OpaquePointer!                // Opaque pointer to Opus Decoder
  private var _engine                       = AVAudioEngine()
  private var _player                       = AVAudioPlayerNode()
  private var _buffers                      = [AVAudioPCMBuffer]()          // non-interleaved buffers (AVAudioPlayer input)
  private var _bufferIndex                  = 0
  private var _interleavedBufferPtr         : UnsafeMutablePointer<Float>
  private var _rxInterleaved                =                               // interleaved buffer (Opus decoder output)
    [Float](repeating: 0.0, count: OpusDecode.kSampleCount * OpusDecode.kNumberOfChannels)

  private let kNumberOfBuffers              = 3
  private let kChannelLeft                  = 0
  private let kChannelRight                 = 1
//  private enum OpusApplication              : Int32 {                       // Opus "application" values
//    case voip                               = 2048
//    case audio                              = 2049
//    case restrictedLowDelay                 = 2051
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {
    // get a pointer to the Interleaved buffer
    _interleavedBufferPtr = UnsafeMutablePointer<Float>(mutating: _rxInterleaved)

    super.init()

    // create a stereo format with the Opus sample rate
    let opusFormat = AVAudioFormat(standardFormatWithSampleRate: Double(OpusDecode.kSampleRate), channels: 2)!

    // create a stereo format with the Output device sample rate
    
    // create multiple output buffers with the Opus format
    createBuffers(with: opusFormat)

    // create the Opus decoder
    var opusError: Int32 = 0
    _decoder = opus_decoder_create(Int32(OpusDecode.kSampleRate), 2, &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }
    
    // attach the nodes
    _engine.attach(_player)
    
    // connect the nodes
    //
    //  ---- Stream Handler ----        ->      Player input      ->      engine.outputNode output    ->    Audio Device
    //
    // [UInt8]      ->    [Float]       ->      [Float]           ->      [Float]
    //
    // opus               pcmFloat32            pcmFloat32                pcmFloat32
    // 24_000             24_000                24_000                    set by hardware
    // interleaved        interleaved           non-interleaved           non-interleaved
    // 2 channels         2 channels            2 channels                2 channels
    //
    _engine.connect(_player, to: _engine.outputNode, format: opusFormat)

    Log.sharedInstance.msg("Output = \(_engine.outputNode.outputFormat(forBus: 0))", level: .info, function: #function, file: #file, line: #line)

    // start the engine
    try! _engine.start()

    clearBuffers()
    
    _player.play()
  }
  
  deinit {
    _player.stop()
    _engine.stop()
  }
  /// Create one or more AVAudioPCMBuffers
  ///
  /// - Parameter format:           the desired format
  ///
  private func createBuffers(with format: AVAudioFormat) {
    // number of samples in 10 milliseconds
    let sampleCount = format.sampleRate/100
    
    // create kNumberOfBuffers AVAudioPCMBuffers
    for _ in 0..<kNumberOfBuffers {
      
      // buffer with the Opus sample rate and frame size
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))!
      buffer.frameLength = AVAudioFrameCount(sampleCount)

      // sdd it to the collection of buffers
      _buffers.append(buffer)
    }
  }
  /// Clear all buffers
  ///
  private func clearBuffers() {
    _bufferIndex = 0
    
    for buffer in _buffers {
      
      // clear the non-interleaved buffer (fill with zeroes)
      memset(buffer.floatChannelData![kChannelLeft], 0, Int(buffer.frameLength) * MemoryLayout<Float>.size)
      memset(buffer.floatChannelData![kChannelRight], 0, Int(buffer.frameLength) * MemoryLayout<Float>.size)
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - OpusStreamHandler protocol methods
  //      called by Opus, executes on the streamQ
  //
  
  /// Process an Opus Rx stream
  ///
  /// - Parameter frame:            an Opus Rx Frame
  ///
  func streamHandler<T>(_ streamFrame: T) {
    
    guard let frame = streamFrame as? OpusFrame else { return }
    
    guard _player.isPlaying else { return }
    
    // perform Opus decoding
    let numberOfFramesDecoded = opus_decode_float(_decoder,
                                                 frame.samples,
                                                 Int32(frame.numberOfSamples),
                                                 _interleavedBufferPtr,
                                                 Int32(OpusDecode.kSampleCount * MemoryLayout<Float>.size * OpusDecode.kNumberOfChannels),
                                                 Int32(0))
    
    // check for decode errors
    if numberOfFramesDecoded < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(numberOfFramesDecoded)), level: .error, function: #function, file: #file, line: #line) }
    
    // view the current buffer as a DSPSplitComplex
    var nonInterleavedBuffers = DSPSplitComplex(realp: _buffers[_bufferIndex].floatChannelData![kChannelLeft],
                                                imagp: _buffers[_bufferIndex].floatChannelData![kChannelRight])

    // view the interleaved buffer as a DSPComplex
    _interleavedBufferPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { interleavedBuffers in

      // convert from the interleaved buffer (DSPComplex) to the non-interleaved buffer (DSPSplitComplex)
      vDSP_ctoz(interleavedBuffers,
                OpusDecode.kNumberOfChannels,
                &nonInterleavedBuffers,
                1,
                vDSP_Length(numberOfFramesDecoded))
    }
    
    // play the buffer
    _player.scheduleBuffer(_buffers[_bufferIndex])
    
    // move to the next buffer
    _bufferIndex = (_bufferIndex + 1) % kNumberOfBuffers
  }
}
