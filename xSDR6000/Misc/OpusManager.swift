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

  static let kSampleRate                   : Float = 24_000                 // Sample Rate (samples/second)
  static let kNumberOfChannels             = 2                              // Stereo, Right & Left channels
  static let kStereoChannelMask            : Int32 = 0x3
  static let kSampleCount                  = 240                            // Number of input samples
  static let kMaxEncodedBytes              : Int32 = 240                    // max size of encoded frame

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _opus                         : Opus?                         // Opus instance
  private var _decoder                      : OpaquePointer!                // Opaque pointer to Opus Decoder
  private var _encoder                      : OpaquePointer!                // Opaque pointer to Opus Encoder
  private var _rxInterleaved                : [Float]!                      // output of Opus decoder
  private let _rxInterleavedPtr             : UnsafeMutablePointer<Float>!
  private var _rxBufferList                 : UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!
  private var _rxSplitComplex               : DSPSplitComplex
  private var _rxLeftBuffer                 : [Float]!                      // non-interleaved buffer, Left
  private var _rxRightBuffer                : [Float]!                      // non-interleaved buffer, Right
  
  
  var engine                                = AVAudioEngine()
  var player                                = AVAudioPlayerNode()
  var output                                : AVAudioOutputNode!
  
  var buffer1                               : AVAudioPCMBuffer?
  var buffer2                               : AVAudioPCMBuffer?
  var buffer3                               : AVAudioPCMBuffer?
  var activeBuffer                          : AVAudioPCMBuffer?
  
  var currentBuffer                         = 0
  var time                                  : Float = 0.0
  var timeDelta                             : Float = 0.0
  
  var format                                : AVAudioFormat!
//  var outputFormat                          : AVAudioFormat!
  
  private var _timer                        : DispatchSourceTimer!
  private var _timerQ                       = DispatchQueue(label: "AVAudioPlayerTest" + ".timerQ")
  
  private let kNumberOfBuffers              = 3

  var length                                = OpusManager.kSampleCount
  
  let twoPi                                 : Float = 2.0 * 3.14159

  
  
  // constants
  
  
  private enum OpusApplication              : Int32 {                       // Opus "application" values
    case voip                               = 2048
    case audio                              = 2049
    case restrictedLowDelay                 = 2051
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {
    // RX STREAM setup (audio from the Radio to the Mac)
    
    // allocate the interleaved Rx buffer
    _rxInterleaved = [Float](repeating: 0.0, count: OpusManager.kSampleCount * OpusManager.kNumberOfChannels)
    
    // get a raw pointer to the Rx interleaved buffer
    _rxInterleavedPtr = UnsafeMutablePointer<Float>(mutating: _rxInterleaved)!
    
    // allocate the non-interleaved Rx buffers
    _rxLeftBuffer = [Float](repeating: 0.0, count: OpusManager.kSampleCount)
    _rxRightBuffer = [Float](repeating: 0.0, count: OpusManager.kSampleCount)
    
    // allocate an Rx buffer list & initialize it
    _rxBufferList = UnsafeMutablePointer<UnsafeMutablePointer<Float>?>.allocate(capacity: 2)
    _rxBufferList[0] = UnsafeMutablePointer(mutating: _rxLeftBuffer)
    _rxBufferList[1] = UnsafeMutablePointer(mutating: _rxRightBuffer)

    // view the non-interleaved Rx buffers as a DSPSplitComplex (for vDSP)
    _rxSplitComplex = DSPSplitComplex(realp: _rxBufferList[0]!, imagp: _rxBufferList[1]!)

    // create the Opus decoder
    var opusError: Int32 = 0
    _decoder = opus_decoder_create(Int32(OpusManager.kSampleRate), 2, &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }

    super.init()

    // setup the sound output unit
    playerSetup()
  }
  /// Perform any required cleanup
  ///
  deinit {
    
    // de-allocate the Rx buffer list
    _rxBufferList.deallocate()

  }
  /// Start/Stop the Opus Rx stream processing
  ///
  /// - Parameter start:      true = start
  ///
  func rxAudio(_ start: Bool) {
    
//    print("rxAudio - \(start ? "start" : "stop")")
    
    if start {
      currentBuffer = 0
      time = 0.0
      timeDelta = 440.0/OpusManager.kSampleRate

      try! engine.start()
      
      player.play()

    } else {

      player.stop()
    }
  }
  
  func playerSetup() {
    
    format = AVAudioFormat(standardFormatWithSampleRate: Double(OpusManager.kSampleRate), channels: 2)
//    outputFormat = AVAudioFormat(standardFormatWithSampleRate: Double(OpusManager.kSampleRate), channels: 2)
    
    output = engine.outputNode
    
    buffer1 = AVAudioPCMBuffer(pcmFormat: format,frameCapacity:AVAudioFrameCount(length))
    buffer1?.frameLength = AVAudioFrameCount(length)
    buffer2 = AVAudioPCMBuffer(pcmFormat: format,frameCapacity:AVAudioFrameCount(length))
    buffer2?.frameLength = AVAudioFrameCount(length)
    buffer3 = AVAudioPCMBuffer(pcmFormat: format,frameCapacity:AVAudioFrameCount(length))
    buffer3?.frameLength = AVAudioFrameCount(length)
    
    // Connect nodes
    engine.attach(player)
    engine.connect(player, to: output, format: format)
    
//    Swift.print("Input         = \(inputFormat)")
//    Swift.print("Output        = \(outputFormat)")
//    Swift.print("Player output = \(player.outputFormat(forBus: 0))")
//    Swift.print("Buffer length = \(length)")
  }

  // ----------------------------------------------------------------------------
  // MARK: - OpusStreamHandler protocol methods
  //      called by Opus, executes on the streamQ
  //
  
  /// Process an Opus Rx stream
  ///
  /// - Parameter frame: an Opus Rx Frame
  ///
  func streamHandler<T>(_ streamFrame: T) {
    
    guard let frame = streamFrame as? OpusFrame else { return }

    // perform Opus decoding
    let result = opus_decode_float(_decoder, frame.samples, Int32(frame.numberOfSamples), _rxInterleavedPtr, Int32(OpusManager.kSampleCount * MemoryLayout<Float>.size * OpusManager.kNumberOfChannels), Int32(0))
    
    // check for decode errors
    if result < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(result)), level: .error, function: #function, file: #file, line: #line) }
    
    // convert the decoded audio from interleaved (DSPComplex) to non-interleaved (DSPSplitComplex)
    
    _rxInterleavedPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { rxComplexPtr in
      vDSP_ctoz(rxComplexPtr, OpusManager.kNumberOfChannels, &_rxSplitComplex, 1, vDSP_Length(result))
    }

    switch currentBuffer {
    case 0:
      activeBuffer = buffer1!
    case 1:
      activeBuffer = buffer2!
    case 2:
      activeBuffer = buffer3!
    default:
      fatalError()
    }
    
    for i in 0..<length
    {
      activeBuffer!.floatChannelData?.pointee[i] = _rxBufferList[0]!.advanced(by: i).pointee
      activeBuffer!.floatChannelData?.advanced(by: 1).pointee[i] = _rxBufferList[1]!.advanced(by: i).pointee
//      let value = sin(time * twoPi)
//      activeBuffer!.floatChannelData?.pointee[i] = value
//      activeBuffer!.floatChannelData?.advanced(by: 1).pointee[i] = value
//      time += timeDelta
//      if time > 1.0 { time -= 1.0 }
    }
    player.scheduleBuffer(activeBuffer!)
    currentBuffer = (currentBuffer + 1) % kNumberOfBuffers
  }
}
