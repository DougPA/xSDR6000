//
//  OpusEncode.swift
//  xSDR6000
//
//  Created by Douglas Adams on 8/2/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Foundation
import xLib6000
import OpusOSX
import AVFoundation

//  DATA FLOW
//
//  Input device  ->  InputNode Tap     ->     AudioConverter    ->    OpusEncoder      ->    Opus.sendTxAudio()
//
//  various           [Float]           ->     [Float]                 [UInt8]
//
//  various           pcmFloat32               pcmFloat32              opus
//  various           48_000                   24_000                  24_000
//  various           non-interleaved          interleaved             interleaved
//  various           2 channels               2 channels              2 channels
//

// --------------------------------------------------------------------------------
// MARK: - Opus Encode class implementation
// --------------------------------------------------------------------------------


public final class OpusEncode               : NSObject {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _opus                         : Opus!
  private var _encoder                      : OpaquePointer!
  private var _tapBufferSize                : AVAudioFrameCount = 0
  private var _interleavedBuffers           = [AVAudioPCMBuffer]()
  private var _bufferIndex                  = 0
  private var _encodedBuffer                =
    [UInt8](repeating: 0, count: Opus.frameLength)
  private var _engine                       : AVAudioEngine?
  private let _outputFormat                 = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                            sampleRate: Double(Opus.rate),
                                                            channels: AVAudioChannelCount(Opus.channels),
                                                            interleaved: Opus.isInterleaved)!
  private let kTapBus                       = 0
  private let kNumberOfBuffers              = 3

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ opus: Opus) {
    _opus = opus
    
    super.init()
    
    // create output buffers
    for _ in 0..<kNumberOfBuffers {
      _interleavedBuffers.append( AVAudioPCMBuffer(pcmFormat: _outputFormat, frameCapacity: AVAudioFrameCount(_outputFormat.sampleRate/10))!)
    }
    // create the Opus encoder
    var opusError : Int32 = 0
    _encoder = opus_encoder_create(Int32(Opus.rate),
                                   Int32(Opus.channels),
                                   Int32(Opus.application),
                                   &opusError)
    if opusError != OPUS_OK { fatalError("Unable to create OpusEncoder, error = \(opusError)") }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Capture data from the default input device & convert it to the format specified in the opus struct
  ///
  public func capture(_ device: AHAudioDevice) {
    
    // get the input device's ASBD & derive the AVAudioFormat from it
    var asbd = device.asbd!
    let inputFormat = AVAudioFormat(streamDescription: &asbd)!
    
    // create a format for the Tap's output
    let tapFormat = _engine!.inputNode.outputFormat(forBus: kTapBus)
    
    // calculate a buffer size for 10 milliseconds of audio
    _tapBufferSize = AVAudioFrameCount(tapFormat.sampleRate/100)
    
    Swift.print("Input  device  = \(device.name!), ID = \(device.id)")
    Swift.print("Input  format  = \(inputFormat)")
    Swift.print("Tap    format  = \(tapFormat)")
    Swift.print("Output format  = \(_outputFormat)")
    
    // exit if the conversion would be invalid
    guard let audioConverter = AVAudioConverter(from: tapFormat, to: _outputFormat) else { return }
    
    // clear the buffers
    clearBuffers()
    
    // setup the Tap callback
    _engine!.inputNode.installTap(onBus: kTapBus, bufferSize: _tapBufferSize, format: tapFormat) { [unowned self] (inputBuffer, time) in
      
      // setup the Converter callback (assumes no errors)
      var error: NSError?
      audioConverter.convert(to: self._interleavedBuffers[self._bufferIndex], error: &error, withInputFrom: { (inNumPackets, outStatus) -> AVAudioBuffer? in
        
        // signal we have the needed amount of data
        outStatus.pointee = AVAudioConverterInputStatus.haveData
        
        // return the data to be converted
        return inputBuffer
      } )
      
      // perform Opus encoding
      let numberOfFramesEncoded = opus_encode_float(self._encoder,
                                                    self._interleavedBuffers[self._bufferIndex].floatChannelData!.pointee,
                                                    Int32(Opus.frameLength),
                                                    &self._encodedBuffer,
                                                    Int32(Opus.frameLength))
      // check for encode errors
      if numberOfFramesEncoded < 0 { Log.sharedInstance.msg(String(cString: opus_strerror(numberOfFramesEncoded)), level: .error, function: #function, file: #file, line: #line) }

      // send buffer to Radio
      self._opus.sendTxAudio(buffer: self._encodedBuffer)
      
      // bump the buffer index
      self._bufferIndex = (self._bufferIndex + 1)  % self.kNumberOfBuffers
    }
    
    // prepare & start the engine
    _engine!.prepare()
    try! _engine!.start()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Set the input device for the engine
  ///
  /// - Parameter id:             an AudioDeviceID
  /// - Returns:                  true if successful
  ///
  private func setInputDevice(_ id: AudioDeviceID) -> Bool {
    
    // get the underlying AudioUnit
    let audioUnit = _engine!.inputNode.audioUnit!
    
    // set the new device as the input device
    var inputDeviceID = id
    let error = AudioUnitSetProperty(audioUnit,
                                     kAudioOutputUnitProperty_CurrentDevice,
                                     kAudioUnitScope_Global,
                                     0,
                                     &inputDeviceID,
                                     UInt32(MemoryLayout<AudioDeviceID>.size))
    // success if no errors
    return error == noErr
  }
  /// Clear all buffers
  ///
  private func clearBuffers() {
    _bufferIndex = 0
    
    for buffer in _interleavedBuffers {
      
      // clear the interleaved buffer (fill with zeroes)
      memset(buffer.floatChannelData![0], 0, Int(buffer.frameLength) * MemoryLayout<Float>.size * Int(_outputFormat.channelCount))
    }
  }
}
