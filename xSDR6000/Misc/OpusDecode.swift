//
//  OpusDecode.swift
//  xSDR6000
//
//  Created by Douglas Adams on 2/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation
import os.log
import xLib6000
import OpusOSX
import Accelerate
import AVFoundation

//  DATA FLOW
//
//  Stream Handler  ->  Opus Decoder   ->  Conversion   ->  Player output   ->  Output device
//
//                  [UInt8]            [Float]          [Float]             [Float]
//
//                  opus               pcmFloat32       pcmFloat32          pcmFloat32
//                  24_000             24_000           24_000              set by hardware
//                  interleaved        interleaved      non-interleaved     non-interleaved
//                  2 channels         2 channels       2 channels          2 channels

// --------------------------------------------------------------------------------
// MARK: - Opus Decode class implementation
// --------------------------------------------------------------------------------

public final class OpusDecode               : NSObject, StreamHandler {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "OpusDecode")
  private var _decoder                      : OpaquePointer!
  private var _engine                       = AVAudioEngine()
  private var _player                       = AVAudioPlayerNode()
  private var _playerInputBuffers           = [AVAudioPCMBuffer]()          // non-interleaved buffers
  private var _index                        = 0
  private var _decoderOutput                =                               // interleaved buffer
    [Float](repeating: 0.0, count: Opus.frameCount * Opus.channelCount)

  private let kNumberOfPlayerInputBuffers   = 3
  private let kChannelLeft                  = 0
  private let kChannelRight                 = 1
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {

    super.init()

    // create a non-interleaved stereo format with the Opus sample rate
    let opusFormat = AVAudioFormat(standardFormatWithSampleRate: Double(Opus.sampleRate),
                                   channels: AVAudioChannelCount(Opus.channelCount))!

    // create Player input buffers
    createBuffers(with: opusFormat)

    // create the Opus decoder
    createDecoder()
    
    // Create & start the player
    createPlayer(with: opusFormat)
  }
  
  deinit {
    _player.stop()
    _engine.stop()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Create one or more AVAudioPCMBuffers
  ///
  /// - Parameter format:           the desired format
  ///
  private func createBuffers(with format: AVAudioFormat) {
    
    // create the AVAudioPCMBuffers
    for _ in 0..<kNumberOfPlayerInputBuffers {
      
      // buffer with the Opus sample rate and frame count
      let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                    frameCapacity: AVAudioFrameCount(Opus.frameCount))!
      buffer.frameLength = buffer.frameCapacity

      // add it to the collection of buffers
      _playerInputBuffers.append(buffer)
    }
  }
  /// Create an Opus decoder
  ///
  private func createDecoder() {
    
    // create the Opus decoder
    var opusError : Int32 = 0
    _decoder = opus_decoder_create(Int32(Opus.sampleRate),
                                   Int32(Opus.channelCount),
                                   &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }
  }
  /// Create an AVAudioPlayer
  ///
  /// - Parameter opusFormat:         the desired format
  ///
  private func createPlayer(with opusFormat: AVAudioFormat) {
    
    // attach the node
    _engine.attach(_player)
    
    // connect the nodes
    _engine.connect(_player, to: _engine.outputNode, format: opusFormat)
    
    // start the engine
    try! _engine.start()
    
    clearBuffers()
    
    _player.play()
  }
  /// Clear all buffers
  ///
  private func clearBuffers() {
    _index = 0
    
    for buffer in _playerInputBuffers {
      
      // clear the non-interleaved buffer (fill with zeroes)
      memset(buffer.floatChannelData![kChannelLeft],
             0,
             Int(buffer.frameLength) * MemoryLayout<Float>.size)
      
      memset(buffer.floatChannelData![kChannelRight],
             0,
             Int(buffer.frameLength) * MemoryLayout<Float>.size)
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
    
    // ----- Opus Decoding -----
    
    // perform Opus decoding
    let destination = UnsafeMutablePointer<Float>(mutating: _decoderOutput)
    let framesDecoded = opus_decode_float(_decoder,                       // a decoder
                                          frame.samples,                  // source (Opus-encoded bytes)
                                          Int32(frame.numberOfSamples),   // source, number of bytes
                                          destination,                    // destination (interleaved .pcmFloat32)
                                          Int32(Opus.frameCount),         // destination, frames per channel
                                          Int32(0))                       // FEC (none)
    // check for decode errors
    if framesDecoded < 0 {
      os_log("%{public}@", log: _log, type: .error, opus_strerror(framesDecoded))
    }
    
    // ----- Interleave Conversion -----
    
    // view the current Player input buffer (non-interleaved) as a DSPSplitComplex
    var currentPlayerInputBuffer = DSPSplitComplex(realp: _playerInputBuffers[_index].floatChannelData![kChannelLeft],
                                                   imagp: _playerInputBuffers[_index].floatChannelData![kChannelRight])
    
    // view the decoder output buffer (interleaved) as a DSPComplex
    UnsafePointer<Float>(_decoderOutput).withMemoryRebound(to: DSPComplex.self, capacity: 1) { decoderOutput in
      
      // convert from the interleaved buffer (DSPComplex) to the non-interleaved buffer (DSPSplitComplex)
      vDSP_ctoz(decoderOutput,                // source       (interleaved)
                Opus.channelCount,            // source stride
                &currentPlayerInputBuffer,    // destination  (non-interleaved)
                1,                            // destination stride
                vDSP_Length(framesDecoded))   // # of frames
    }

    // ----- Output -----
    
    // play the (non-interleaved) buffer
    _player.scheduleBuffer(_playerInputBuffers[_index])
    
    // move to the next buffer
    _index = (_index + 1) % kNumberOfPlayerInputBuffers
  }
}
