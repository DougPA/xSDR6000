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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _opus                         : Opus?                         // Opus instance
  private var _decoder                      : OpaquePointer!                // Opaque pointer to Opus Decoder
  private var _encoder                      : OpaquePointer!                // Opaque pointer to Opus Encoder
  private let _audioManager                 = AFManager()                   // AudioLibrary manager
  private var _tenMsSampleCount             : Int!                          // Number of decoded samples expected
  
  private let _outputSoundcard              : AFSoundcard?                  // audio output device
  private var _rxInterleaved                : [Float]!                      // output of Opus decoder
  private let _rxInterleavedPtr             : UnsafeMutablePointer<Float>!
  private var _rxBufferList                 : UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!
  private var _rxSplitComplex               : DSPSplitComplex
  private let _rxLeftBuffer                 : [Float]!                      // non-interleaved buffer, Left
  private let _rxRightBuffer                : [Float]!                      // non-interleaved buffer, Right
  
  private let _inputSoundcard               : AFSoundcard?                  // audio input device
  private var _txInterleaved                : [Float]!
  private let _txInterleavedPtr             : UnsafeMutablePointer<Float>!
  private let _txLeftBuffer                 : [Float]!                      // non-interleaved buffer, Left
  private let _txRightBuffer                : [Float]!                      // non-interleaved buffer, Right
  private var _txEncodedBuffer              : [UInt8]!
  
  
  // constants
  private let kModule                       = "OpusDecoder"                 // Module Name reported in log messages
  private let kSampleRate                   : Float = 24_000                // Sample Rate (samples/second)
  private let kNumberOfChannels             = 2                             // Stereo, Right & Left channels
  private let kStereoChannelMask            : Int32 = 0x3
  private let kSampleCount                  : Int32 = 240                   // Number of input samples
  
  private let kMaxEncodedBytes              = 240                           // max size of encoded frame
  
  private enum OpusApplication              : Int32 {                       // Opus "application" values
    case voip                               = 2048
    case audio                              = 2049
    case restrictedLowDelay                 = 2051
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {
    // 10 ms worth
    _tenMsSampleCount = Int(kSampleRate * 0.01)
    
    // RX STREAM setup (audio from the Radio to the Mac)
    
    // setup the sound output unit
    _outputSoundcard = _audioManager.newOutputSoundcard()
    guard _outputSoundcard != nil else { fatalError("Unable to create output sound card") }
    _outputSoundcard!.setSamplingRate(kSampleRate)
    _outputSoundcard!.setResamplingRate(kSampleRate)
    _outputSoundcard!.setBufferLength(Int32(_tenMsSampleCount))
    _outputSoundcard!.setChannelMask(kStereoChannelMask)
    
    // allocate the interleaved Rx buffer
    _rxInterleaved = [Float](repeating: 0.0, count: _tenMsSampleCount * kNumberOfChannels)
    
    // get a raw pointer to the Rx interleaved buffer
    _rxInterleavedPtr = UnsafeMutablePointer<Float>(mutating: _rxInterleaved)!
    
    // allocate the non-interleaved Rx buffers
    _rxLeftBuffer = [Float](repeating: 0.0, count: _tenMsSampleCount)
    _rxRightBuffer = [Float](repeating: 0.0, count: _tenMsSampleCount)
    
    // allocate an Rx buffer list & initialize it
    _rxBufferList = UnsafeMutablePointer<UnsafeMutablePointer<Float>?>.allocate(capacity: 2)
    _rxBufferList[0] = UnsafeMutablePointer(mutating: _rxLeftBuffer)
    _rxBufferList[1] = UnsafeMutablePointer(mutating: _rxRightBuffer)
    
    // view the non-interleaved Rx buffers as a DSPSplitComplex (for vDSP)
    _rxSplitComplex = DSPSplitComplex(realp: _rxBufferList[0]!, imagp: _rxBufferList[1]!)
    
    // create the Opus decoder
    var opusError: Int32 = 0
    _decoder = opus_decoder_create(Int32(kSampleRate), 2, &opusError)
    if opusError != 0 { fatalError("Unable to create OpusDecoder, error = \(opusError)") }
    
    // TX STREAM setup (audio from the Mac to the Radio)
    
    // setup the sound input unit
    _inputSoundcard = _audioManager.newInputSoundcard()
    guard _inputSoundcard != nil else { fatalError("Unable to create input sound card") }
    _inputSoundcard!.setSamplingRate(kSampleRate)
    _inputSoundcard!.setBufferLength(Int32(_tenMsSampleCount))
    _inputSoundcard!.setChannelMask(kStereoChannelMask)
    
    // initialize the interleaved Tx encoded buffer
    _txEncodedBuffer = [UInt8](repeating: 0, count: _tenMsSampleCount)
    
    // allocate the non-interleaved Tx buffers
    _txLeftBuffer = [Float](repeating: 0.0, count: _tenMsSampleCount)
    _txRightBuffer = [Float](repeating: 0.0, count: _tenMsSampleCount)
    
    _txInterleaved = [Float](repeating: 0.0, count: 2 * _tenMsSampleCount)
    _txInterleavedPtr = UnsafeMutablePointer<Float>(mutating: _txInterleaved)!
    
    // create the Opus encoder
    _encoder = opus_encoder_create(Int32(kSampleRate), 2, OpusApplication.audio.rawValue, &opusError)
    if opusError != 0 { fatalError("Unable to create OpusEncoder, error = \(opusError)") }
    
    super.init()
    
    _inputSoundcard!.setDelegate(self)
    _outputSoundcard!.setDelegate(self)
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
    
    //        print("rxAudio - \(start ? "start" : "stop")")
    
    if start {
      _outputSoundcard?.start()
    } else {
      _outputSoundcard?.stop()
    }
  }
  /// Start/Stop the Opus Tx stream processing
  ///
  /// - Parameter start:      true = start
  ///
  func txAudio(_ start: Bool, opus: Opus) {
    
    //        print("txAudio - \(start ? "start" : "stop")")
    _opus = opus
    
    if start {
      _inputSoundcard?.start()
    } else {
      _inputSoundcard?.stop()
    }
  }
  
  func inputReceived(from card: AFSoundcard!, buffers: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, numberOfBuffers n: Int32, samples: Int32) {
    
    // buffers is a "bufferList" with buffers[0] = left & buffers[1] = right
    
    assert(samples == kSampleCount, "Opus Tx Samples != \(_tenMsSampleCount)")
    assert(n == Int32(kNumberOfChannels), "Opus Tx Number of channels != \(kNumberOfChannels)")
    
    print("level = \(buffers[0]![119])")
    
    
    // make sure we have stereo
    guard n == 2 else {
      Log.sharedInstance.msg("Opus Tx, input not stereo", level: .error, function: #function, file: #file, line: #line)
      return
    }
    // view the non-interleaved data as a DSPSplitComplex
    var txSplitComplex = DSPSplitComplex(realp: buffers[0]!, imagp: buffers[1]!)
    
    // view the interleaved data as a DSPComplex
    _txInterleavedPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { txComplexPtr in
      
      // convert the incoming audio from non-interleaved (DSPSplitComplex) to interleaved (DSPComplex)
      vDSP_ztoc(&txSplitComplex, vDSP_Stride(1), txComplexPtr, vDSP_Stride(2), vDSP_Length(samples))
    }
    // Opus encode the audio into the Tx Interleaved buffer
    let result = opus_encode_float(_encoder, UnsafePointer<Float>(_txInterleaved), samples, UnsafeMutablePointer<UInt8>(mutating: _txEncodedBuffer), Int32(kMaxEncodedBytes))
    
    // check for encode errors
    if result < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(result)), level: .error, function: #function, file: #file, line: #line) }
    
    // send the audio to the Radio
    _opus?.sendOpusTxAudio(buffer: _txEncodedBuffer, samples: Int(result))
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
    let result = opus_decode_float(_decoder, frame.samples, Int32(frame.numberOfSamples), _rxInterleavedPtr, Int32(_tenMsSampleCount * MemoryLayout<Float>.size * kNumberOfChannels), Int32(0))
    
    // check for decode errors
    if result < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(result)), level: .error, function: #function, file: #file, line: #line) }
    
    // convert the decoded audio from interleaved (DSPComplex) to non-interleaved (DSPSplitComplex)
    _rxInterleavedPtr.withMemoryRebound(to: DSPComplex.self, capacity: 1) { rxComplexPtr in
      vDSP_ctoz(rxComplexPtr, kNumberOfChannels, &_rxSplitComplex, 1, vDSP_Length(result))
    }
    // push the non-interleaved audio to the output device
    _outputSoundcard?.pushBuffers(_rxBufferList, numberOfBuffers: Int32(kNumberOfChannels), samples: Int32(result), rateScalar: 1.0)
  }
}
