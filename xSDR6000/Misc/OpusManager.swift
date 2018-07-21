//
//  OpusManager.swift
//  xSDR6000
//
//  Created by Douglas Adams on 2/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation
import xLib6000
import OpusOSX
import AudioLibrary
import Accelerate
import AVFoundation


class OpusManager                           : NSObject, StreamHandler, AFSoundcardDelegate {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kSampleRate                    : Float = 48_000                 // Sample Rate (samples/second)
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
    [Float](repeating: 0.0, count: OpusManager.kSampleCount * OpusManager.kNumberOfChannels)

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
    let format = AVAudioFormat(standardFormatWithSampleRate: Double(OpusManager.kSampleRate), channels: 2)!
    createBuffers(with: format)
    
    // create the Opus decoder
    var opusError: Int32 = 0
    _decoder = opus_decoder_create(Int32(OpusManager.kSampleRate), 2, &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }
    
    // Connect AVAudioPlayer nodes & start the engine
    _engine.attach(_player)
    _engine.connect(_player, to: _engine.outputNode, format: format)
    try! _engine.start()

    clearBuffers()
    
    _player.play()
  }
  
  deinit {
    
    _player.stop()
  }
  /// Create one or more AVAudioPCMBuffers
  ///
  /// - Parameter format:           the desired format
  ///
  private func createBuffers(with format: AVAudioFormat) {
    
    // create kNumberOfBuffers AVAudioPCMBuffers with the Opus sample rate and frame size
    for _ in 0..<kNumberOfBuffers {
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity:AVAudioFrameCount(OpusManager.kSampleCount))!
      buffer.frameLength = AVAudioFrameCount(OpusManager.kSampleCount)

      _buffers.append(buffer)
    }
  }
  /// Clear all buffers
  ///
  private func clearBuffers() {
    _bufferIndex = 0
    
    // clear the buffers (fill with zeroes)
    for buffer in _buffers {
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
    let result = opus_decode_float(_decoder, frame.samples,
                                   Int32(frame.numberOfSamples),
                                   _interleavedBufferPtr,
                                   Int32(OpusManager.kSampleCount * MemoryLayout<Float>.size * OpusManager.kNumberOfChannels),
                                   Int32(0))
    
    // check for decode errors
    if result < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(result)), level: .error, function: #function, file: #file, line: #line) }
    
    // view the current buffer as a DSPSplitComplex
    var nonInterleavedBuffers = DSPSplitComplex(realp: _buffers[_bufferIndex].floatChannelData![kChannelLeft],
                                       imagp: _buffers[_bufferIndex].floatChannelData![kChannelRight])

    // view the interleaved buffer as a DSPComplex
    _interleavedBufferPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { interleavedBuffers in
      // convert from the interleaved buffer (DSPComplex) to the non-interleaved buffer (DSPSplitComplex)
      vDSP_ctoz(interleavedBuffers,
                OpusManager.kNumberOfChannels,
                &nonInterleavedBuffers,
                1,
                vDSP_Length(result))
    }
    // play the buffer
    _player.scheduleBuffer(_buffers[_bufferIndex])
    
    // move to the next buffer
    _bufferIndex = (_bufferIndex + 1) % kNumberOfBuffers
  }
}
