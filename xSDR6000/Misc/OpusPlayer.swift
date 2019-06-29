//
//  OpusPlayer.swift
//  xSDR6000
//
//  Created by Douglas Adams on 2/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation
import xLib6000
import OpusOSX
import Accelerate
import AudioToolbox

//  DATA FLOW
//
//  Stream Handler  ->  Opus Decoder   ->   Ring Buffer   ->  OutputUnit    -> Output device
//
//                  [UInt8]            [Float]            [Float]           set by hardware
//
//                  opus               pcmFloat32         pcmFloat32
//                  24_000             24_000             24_000
//                  2 channels         2 channels         2 channels
//                                     interleaved        interleaved
// --------------------------------------------------------------------------------
// MARK: - Opus Player class implementation
// --------------------------------------------------------------------------------

public final class OpusPlayer                       : NSObject, StreamHandler {

  static let frequency          : Float64 = 440.0
  
  static let sampleRate         : Float64 = 24_000
  static let numberOfFrames     = 240                           // number of Frames in each buffer
  static let elementSize        = MemoryLayout<Float>.size      // size of an element in the buffer (in Bytes)
  static let numberOfChannels   = 2                             // number of channels in each AudioBufferList
  static let bufferSize         = numberOfFrames * elementSize  // size of a buffer (in Bytes)
  static let ringBufferCapacity = 10                            // number of AudioBufferLists in the Ring buffer
  static let ringBufferOverage  = 2_048                         // allowance for Ring buffer metadata (in Bytes)
  static let ringBufferSize     = (OpusPlayer.bufferSize * OpusPlayer.numberOfChannels * OpusPlayer.ringBufferCapacity) + OpusPlayer.ringBufferOverage

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                                  = NSApp.delegate as! AppDelegate

  private var _asbd                                 = AudioStreamBasicDescription()
  private var _decoder                              : OpaquePointer!
  private var _decoderOutputBuffer                  = [Float](repeating: 0.0, count: OpusPlayer.numberOfFrames * OpusPlayer.numberOfChannels)
  private var _decoderOutputBufferList              : AudioBufferList!
  private var _decoderOutputBufferListPtr           : UnsafeMutableAudioBufferListPointer!
  private var _isPlaying                            = false
  private var _outputUnit                           : AudioUnit?
  private var _ringBuffer                           = TPCircularBuffer()


  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init() {

    super.init()

    createBuffers()
    
    createDecoder()
    
    setupOutputUnit()
  }
  
  deinit {
    guard let outputUnit = _outputUnit else { return }
    AudioUnitUninitialize(outputUnit)
    AudioComponentInstanceDispose(outputUnit)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func startOpusRx() {
    
    guard let outputUnit = _outputUnit else { fatalError("Output unit is null") }
    
    // start playing
    guard AudioOutputUnitStart(outputUnit) == noErr else { fatalError("Output unit failed to start") }
    _isPlaying = true
  }
  
  public func stopOpusRx() {
    
    // shutdown
    _isPlaying = false
    
    guard let outputUnit = _outputUnit else { return }
    
    AudioOutputUnitStop(outputUnit)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Create buffers
  ///
  private func createBuffers() {
    
    // set the appropriate properties (PCM Float32 interleaved)
    memset(&_asbd, 0, MemoryLayout<AudioStreamBasicDescription>.size)
    _asbd.mSampleRate = OpusPlayer.sampleRate                                                   // sample rate
    _asbd.mFormatID = kAudioFormatLinearPCM                                                     // format
    _asbd.mFormatFlags = kAudioFormatFlagIsFloat                                                // elements are Floats
    _asbd.mBitsPerChannel = UInt32(OpusPlayer.elementSize * 8)                                  // bits in each Frame of a Channel
    _asbd.mChannelsPerFrame = 2                                                                 // number of channels in a Frame
    _asbd.mFramesPerPacket = 1                                                                  // number of Frames in a Packet
    _asbd.mBytesPerFrame = UInt32(OpusPlayer.elementSize * OpusPlayer.numberOfChannels)         // number of bytes in a Frame
    _asbd.mBytesPerPacket = _asbd.mBytesPerFrame * _asbd.mFramesPerPacket                       // number of bytes in a Packet
    
    // setup the Decoder Output buffer
    _decoderOutputBufferListPtr = AudioBufferList.allocate(maximumBuffers: 1)
    _decoderOutputBufferListPtr[0] = AudioBuffer(mNumberChannels: 2, mDataByteSize: UInt32(OpusPlayer.bufferSize * OpusPlayer.numberOfChannels), mData: &_decoderOutputBuffer)
    
    // create the Ring buffer (actual size will be adjusted to fit virtual memory page size)
    guard _TPCircularBufferInit( &_ringBuffer, UInt32(OpusPlayer.ringBufferSize), MemoryLayout<TPCircularBuffer>.stride ) else { fatalError("Ring Buffer not created") }
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
  // --------------------------------------------------------------------------------------------
  //
  /// Setup the Output Unit
  ///
  func setupOutputUnit()
  {
    // create an Audio Component Description
    var outputcd = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                             componentSubType: kAudioUnitSubType_DefaultOutput,
                                             componentManufacturer: kAudioUnitManufacturer_Apple,
                                             componentFlags: 0,
                                             componentFlagsMask: 0)
    // get the output device
    guard let audioComponent = AudioComponentFindNext(nil, &outputcd) else { fatalError("Output unit not found") }
    
    // create the player's output unit
    guard AudioComponentInstanceNew(audioComponent, &_outputUnit) == noErr else { fatalError("Output unit not created") }
    guard let outputUnit = _outputUnit else { fatalError("Output unit is null") }
    
    
    // set the output unit's Input sample rate
    var inputSampleRate = OpusPlayer.sampleRate
    AudioUnitSetProperty(outputUnit,
                         kAudioUnitProperty_SampleRate,
                         kAudioUnitScope_Input,
                         0,
                         &inputSampleRate,
                         UInt32(MemoryLayout<Float64>.size))
    
    // set the output unit's Input stream format (PCM Float32 interleaved)
    var inputStreamFormat = _asbd
    AudioUnitSetProperty(outputUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &inputStreamFormat,
                         UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
    
    // register render callback
    var input: AURenderCallbackStruct = AURenderCallbackStruct(inputProc: RenderProc, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
    AudioUnitSetProperty(outputUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,
                         &input,
                         UInt32(MemoryLayout.size(ofValue: input)))
    guard AudioUnitInitialize(outputUnit) == noErr else { fatalError("Output unit not initialized") }
  }

  // --------------------------------------------------------------------------------------------
  //
  /// Render proc
  ///
  ///   returns PCM Float32 interleaved data
  ///
  private let RenderProc: AURenderCallback = {
    (
    inRefCon           : UnsafeMutableRawPointer,
    ioActionFlags      : UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp        : UnsafePointer<AudioTimeStamp>,
    inBusNumber        : UInt32,
    inNumberFrames     : UInt32,
    ioData             : UnsafeMutablePointer<AudioBufferList>?
    ) in
    
    guard let ioData = ioData else { fatalError("ioData is null") }

    // get a reference to the OpusPlayer
    let player = Unmanaged<OpusPlayer>.fromOpaque(inRefCon).takeUnretainedValue()

    // retrieve the requested number of frames
    var lengthInFrames = inNumberFrames
    TPCircularBufferDequeueBufferListFrames(&player._ringBuffer, &lengthInFrames, ioData, nil, &player._asbd)

    // assumes no error
    return noErr
  }

  // ----------------------------------------------------------------------------
  // MARK: - OpusStreamHandler protocol methods
  //
  
  /// Process the UDP Stream Data for Opus Rx
  ///
  ///   StreamHandler protocol, executes on the streamQ
  ///
  /// - Parameter frame:            an Opus Rx Frame
  ///
  public func streamHandler<T>(_ streamFrame: T) {
    var numberOfFramesDecoded : Int32 = 0
    
    guard let frame = streamFrame as? OpusFrame else { return }
    
    guard _isPlaying else { return }

    // ----- Opus Decoding -----

    // Incoming Stream -> _inputBuffer (PCM Float32 interleaved)

    // perform Opus decoding
    numberOfFramesDecoded = opus_decode_float(_decoder,                       // a decoder
      frame.samples,                      // source (Opus-encoded bytes)
      Int32(frame.numberOfSamples),       // source, number of bytes
      &_decoderOutputBuffer,                      // destination (PCM FLoat32 interleaved)
      Int32(OpusPlayer.numberOfFrames),   // destination, number of frames per channel
      0)                                  // FEC (none)

    // check for decode errors
    if numberOfFramesDecoded < 0 {
      _log.msg("\(String(cString: opus_strerror(numberOfFramesDecoded)))", level: .error, function: #function, file: #file, line: #line)
    }

    // copy the Input buffer to the Ring buffer & make it available
    let success = TPCircularBufferCopyAudioBufferList(&_ringBuffer, _decoderOutputBufferListPtr!.unsafeMutablePointer, nil, UInt32(OpusPlayer.numberOfFrames), &_asbd)
    if !success { _log.msg("Failed to write to the Ring Buffer", level: .error, function: #function, file: #file, line: #line) }
  }
}
