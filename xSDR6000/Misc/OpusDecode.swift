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

//  DATA FLOW
//
//  ---- Stream Handler ----        ->     Player input    ->      engine.outputNode output    ->    Output device
//
//  [UInt8]      ->    [Float]      ->     [Float]         ->      [Float]
//
//  opus               pcmFloat32          pcmFloat32              pcmFloat32
//  24_000             24_000              24_000                  set by hardware
//  interleaved        interleaved         non-interleaved         non-interleaved
//  2 channels         2 channels          2 channels              2 channels
//

// --------------------------------------------------------------------------------
// MARK: - Opus Decode class implementation
// --------------------------------------------------------------------------------

public final class OpusDecode               : NSObject, StreamHandler {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _decoder                      : OpaquePointer!                // Opaque pointer to Opus Decoder
  private var _engine                       = AVAudioEngine()
  private var _player                       = AVAudioPlayerNode()
  private var _nonInterleavedBuffers        = [AVAudioPCMBuffer]()          // non-interleaved buffers (AVAudioPlayer input)
  private var _bufferIndex                  = 0
  private var _interleavedBuffer            =                               // interleaved buffer (Opus decoder output)
    [Float](repeating: 0.0, count: Opus.frameLength * Opus.channels)

  private let kNumberOfBuffers              = 3
  private let kChannelLeft                  = 0
  private let kChannelRight                 = 1
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {

    super.init()

    // create a stereo format with the Opus sample rate & non-interleaved
    let opusFormat = AVAudioFormat(standardFormatWithSampleRate: Double(Opus.rate), channels: AVAudioChannelCount(Opus.channels))!

    // create multiple output buffers with the Opus format
    createBuffers(with: opusFormat)

    // create the Opus decoder
    var opusError: Int32 = 0
    _decoder = opus_decoder_create(Int32(Opus.rate), Int32(Opus.channels), &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }
    
    // attach the node
    _engine.attach(_player)
    
    // connect the nodes
    _engine.connect(_player, to: _engine.outputNode, format: opusFormat)

//    Log.sharedInstance.msg("Output = \(_engine.outputNode.outputFormat(forBus: 0))", level: .info, function: #function, file: #file, line: #line)

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
    
    // create the AVAudioPCMBuffers
    for _ in 0..<kNumberOfBuffers {
      
      // buffer with the Opus sample rate and frame size
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Opus.frameLength))!
      buffer.frameLength = buffer.frameCapacity

      // sdd it to the collection of buffers
      _nonInterleavedBuffers.append(buffer)
    }
  }
  /// Clear all buffers
  ///
  private func clearBuffers() {
    _bufferIndex = 0
    
    for buffer in _nonInterleavedBuffers {
      
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
  public func streamHandler<T>(_ streamFrame: T) {
    
    guard let frame = streamFrame as? OpusFrame else { return }
    
    guard _player.isPlaying else { return }
    
    // perform Opus decoding
    let numberOfFramesDecoded = opus_decode_float(_decoder,
                                                 frame.samples,
                                                 Int32(frame.numberOfSamples),
                                                 UnsafeMutablePointer<Float>(mutating: _interleavedBuffer),
                                                 Int32(Opus.frameLength * MemoryLayout<Float>.size * Opus.channels),
                                                 Int32(0))
    
    // check for decode errors
    if numberOfFramesDecoded < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(numberOfFramesDecoded)), level: .error, function: #function, file: #file, line: #line) }
    
    // view the current buffer as a DSPSplitComplex
    var dspSplitComplexBuffer = DSPSplitComplex(realp: _nonInterleavedBuffers[_bufferIndex].floatChannelData![kChannelLeft],
                                                imagp: _nonInterleavedBuffers[_bufferIndex].floatChannelData![kChannelRight])
    
    // view the interleaved buffer as a DSPComplex
    UnsafePointer<Float>(_interleavedBuffer).withMemoryRebound(to: DSPComplex.self, capacity: 1) { dspComplexBuffer in
      
      // convert from the interleaved buffer (DSPComplex) to the non-interleaved buffer (DSPSplitComplex)
      vDSP_ctoz(dspComplexBuffer,
                Opus.channels,
                &dspSplitComplexBuffer,
                1,
                vDSP_Length(numberOfFramesDecoded))
    }
    // play the buffer
    _player.scheduleBuffer(_nonInterleavedBuffers[_bufferIndex])
    
    // move to the next buffer
    _bufferIndex = (_bufferIndex + 1) % kNumberOfBuffers
  }
}
