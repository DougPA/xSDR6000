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
  private let _audioManager                 = AFManager()                   // AudioLibrary manager
  
  private let _outputSoundcard              : AFSoundcard?                  // audio output device
  private var _rxInterleaved                : [Float]!                      // output of Opus decoder
  private let _rxInterleavedPtr             : UnsafeMutablePointer<Float>!
  private var _rxBufferList                 : UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!
  private var _rxSplitComplex               : DSPSplitComplex
  private let _rxLeftBuffer                 : [Float]!                      // non-interleaved buffer, Left
  private let _rxRightBuffer                : [Float]!                      // non-interleaved buffer, Right
  
//  private let _inputSoundcard               : AFSoundcard?                  // audio input device
//  private var _txInterleaved                : [Float]!
//  private let _txInterleavedPtr             : UnsafeMutablePointer<Float>!
//  private let _txLeftBuffer                 : [Float]!                      // non-interleaved buffer, Left
//  private let _txRightBuffer                : [Float]!                      // non-interleaved buffer, Right
//  private var _txEncodedBuffer              : [UInt8]!
  
  
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
    
    // setup the sound output unit
    _outputSoundcard = _audioManager.newOutputSoundcard()
    guard _outputSoundcard != nil else { fatalError("Unable to create output sound card") }
    _outputSoundcard!.setSamplingRate(OpusManager.kSampleRate)
    _outputSoundcard!.setResamplingRate(OpusManager.kSampleRate)
    _outputSoundcard!.setBufferLength(Int32(OpusManager.kSampleCount))
    _outputSoundcard!.setChannelMask(OpusManager.kStereoChannelMask)
    
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
    
//    // TX STREAM setup (audio from the Mac to the Radio)
//
//    // setup the sound input unit
//    _inputSoundcard = _audioManager.newInputSoundcard()
//    guard _inputSoundcard != nil else { fatalError("Unable to create input sound card") }
//    _inputSoundcard!.setSamplingRate(OpusManager.kSampleRate)
//    _inputSoundcard!.setBufferLength(Int32(OpusManager.kSampleCount))
//    _inputSoundcard!.setChannelMask(OpusManager.kStereoChannelMask)
//
//    // initialize the interleaved Tx encoded buffer
//    _txEncodedBuffer = [UInt8](repeating: 0, count: OpusManager.kSampleCount)
//
//    // allocate the non-interleaved Tx buffers
//    _txLeftBuffer = [Float](repeating: 0.0, count: OpusManager.kSampleCount)
//    _txRightBuffer = [Float](repeating: 0.0, count: OpusManager.kSampleCount)
//
//    _txInterleaved = [Float](repeating: 0.0, count: 2 * OpusManager.kSampleCount)
//    _txInterleavedPtr = UnsafeMutablePointer<Float>(mutating: _txInterleaved)!
//
//    // create the Opus encoder
//    _encoder = opus_encoder_create(Int32(OpusManager.kSampleRate), 2, OpusApplication.audio.rawValue, &opusError)
//    if opusError != 0 { fatalError("Unable to create OpusEncoder, error = \(opusError)") }
    
    super.init()
    
//    _inputSoundcard!.setDelegate(self)
    _outputSoundcard!.setDelegate(self)
    _outputSoundcard!.start()
  }
  /// Perform any required cleanup
  ///
  deinit {
    
    // stop output (if any)
    _outputSoundcard?.stop()
    
    // de-allocate the Rx buffer list
//    _rxBufferList.deallocate(capacity: 2)
    _rxBufferList.deallocate()

  }
  /// Start/Stop the Opus Rx stream processing
  ///
  /// - Parameter start:      true = start
  ///
  func rxAudio(_ start: Bool) {
    
    print("rxAudio - \(start ? "start" : "stop")")
    
//    if start {
//      _outputSoundcard?.start()
//      _opus?.createRxAudio(true)
//      
//    } else {
//      _outputSoundcard?.stop()
//      _opus?.createRxAudio(false)
//    }
  }
  /// Start/Stop the Opus Tx stream processing
  ///
  /// - Parameter start:      true = start
  ///
  func txAudio(_ start: Bool, opus: Opus) {
    
    //        print("txAudio - \(start ? "start" : "stop")")
//    _opus = opus
//    
//    if start {
//      _inputSoundcard?.start()
//    } else {
//      _inputSoundcard?.stop()
//    }
  }
  
//  func inputReceived(from card: AFSoundcard!, buffers: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, numberOfBuffers n: Int32, samples: Int32) {
//    
//    // buffers is a "bufferList" with buffers[0] = left & buffers[1] = right
//    
//    assert(samples == OpusManager.kSampleCount, "Opus Tx Samples != \(OpusManager.kSampleCount)")
//    assert(n == Int32(OpusManager.kNumberOfChannels), "Opus Tx Number of channels != \(OpusManager.kNumberOfChannels)")
//    
//    print("level = \(buffers[0]![119])")
//    
//    
//    // make sure we have stereo
//    guard n == 2 else {
//      Log.sharedInstance.msg("Opus Tx, input not stereo", level: .error, function: #function, file: #file, line: #line)
//      return
//    }
//    // view the non-interleaved data as a DSPSplitComplex
//    var txSplitComplex = DSPSplitComplex(realp: buffers[0]!, imagp: buffers[1]!)
//    
//    // view the interleaved data as a DSPComplex
//    _txInterleavedPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { txComplexPtr in
//      
//      // convert the incoming audio from non-interleaved (DSPSplitComplex) to interleaved (DSPComplex)
//      vDSP_ztoc(&txSplitComplex, vDSP_Stride(1), txComplexPtr, vDSP_Stride(2), vDSP_Length(samples))
//    }
//    // Opus encode the audio into the Tx Interleaved buffer
//    let result = opus_encode_float(_encoder, UnsafePointer<Float>(_txInterleaved), samples, UnsafeMutablePointer<UInt8>(mutating: _txEncodedBuffer), OpusManager.kMaxEncodedBytes)
//    
//    // check for encode errors
//    if result < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(result)), level: .error, function: #function, file: #file, line: #line) }
//    
//    // send the audio to the Radio
//    _opus?.sendTxAudio(buffer: _txEncodedBuffer, samples: Int(result))
//  }
  
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
    // push the non-interleaved audio to the output device
    _outputSoundcard?.pushBuffers(_rxBufferList, numberOfBuffers: Int32(OpusManager.kNumberOfChannels), samples: Int32(result), rateScalar: 1.0)
  }
}
