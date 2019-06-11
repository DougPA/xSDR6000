//
//  WaterfallRenderer.swift
//  Waterfall
//
//  Created by Douglas Adams on 10/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation
import xLib6000
import MetalKit

public final class WaterfallRenderer: NSObject, MTKViewDelegate {
  
  
  //  Vertices    v1  (-1, 1)     |     ( 1, 1)  v3       Texture     v1  ( 0, 0) |---------  ( 1, 0)  v3
  //  (-1 to +1)                  |                       (0 to 1)                |
  //                          ----|----                                           |
  //                              |                                               |
  //              v0  (-1,-1)     |     ( 1,-1)  v2                   v0  ( 0, 1) |           ( 1, 1)  v2
  //
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  var updateNeeded                          = true                          // true == recalc texture coords
  
  struct Intensity {
    var i                                   : UInt16 = 0                    // Intensity struct
  }
  
  struct Line {                                                             // Line struct
    var firstBinFrequency                   : Float = 0.0
    var binBandwidth                        : Float = 0.0
    var number                              : UInt16 = 0
  }
  
  struct Constant {                                                         // Constant struct
    var blackLevel                          : UInt16 = 0
    var colorGain                           : UInt16 = 0
    var offsetY                             : UInt16 = 0                    //
    var numberOfLines                       : UInt16 = 0                    //
    var startingFrequency                   : Float = 0.0
    var endingFrequency                     : Float = 0.0
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _radio                   : Radio?
  private weak var _panadapter              : Panadapter?
  private weak var _waterfall               : Waterfall? { return _radio!.waterfalls[_panadapter!.waterfallId] }

  private var _center                       : Int {return _panadapter!.center }
  private var _bandwidth                    : Int { return _panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  
  private var _metalView                    : MTKView!
  private var _commandQueue                 : MTLCommandQueue!              // Metal queue
  private var _line                         = Line()
  private var _constant                     = Constant()
  private var _device                       : MTLDevice!
  private var _gradientSamplerState         : MTLSamplerState!              // sampler for gradient
  private var _gradientTexture              : MTLTexture!                   // color gradient
  private var _intensityBuffer              : MTLBuffer!
  private var _lineBuffer                   : MTLBuffer!
  private var _pipelineState                : MTLRenderPipelineState!       // render pipeline state
  
  private let _waterQ                       = DispatchQueue(label: Api.kId + ".waterQ", attributes: [.concurrent])
  private var _waterDrawQ                   = DispatchQueue(label: Api.kId + ".waterDrawQ")

  private var _autoBlackLevel               : UInt32 = 0
  
  // constants
  private let kFragmentShader               = "waterfall_fragment"          // name of waterfall fragment function
  private let kVertexShader                 = "waterfall_vertex"            // name of waterfall vertex function
  
  // values chosen to accomodate the largest possible waterfall
  private let kMaxLines                     = 2048                          // must be >= max number of lines
  private let kMaxIntensities               = 3360                          // must be >= max number of Bins
  
  // arbitrary choice of a reasonable number of color gradations for the waterfall
  private let kGradientSize                  = 256                           // number of colors in a gradient
  
  // in real waterfall these are properties that change
  static let kEndingBin                     = (kNumberOfBins - 1 - kStartingBin)  // last bin on screen
  static let kFrameHeight                   = 270                           // frame height (pixels)
  static let kFrameWidth                    = 480                           // frame width (pixels)
  static let kNumberOfBins                  = 2048                          // number of stream samples
  static let kStartingBin                   = (kNumberOfBins -  kFrameWidth)  / 2 // first bin on screen
  
  private var _numberOfVertices             = 0
//  private var _numberOfLines                = 0
  private var _sizeOfLine                   = 0
//  private var _sizeOfVertices               = 0
  private var _topLine                      : UInt16 = 0
  private var _first                        = true
  
  private var intensityTestData             = [Intensity]()
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(view: MTKView, radio: Radio, panadapter: Panadapter) {
    
    _metalView = view
    _radio = radio
    _panadapter = panadapter
    
    super.init()
  }
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// The size of the MetalKit View has changed
  ///
  /// - Parameters:
  ///   - view:         the MetalKit View
  ///   - size:         its new size
  ///
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    // TODO:
    setConstants(size: view.frame.size)
  }
  /// Draw lines colored by the Gradient texture
  ///
  /// - Parameter view: the MetalKit view
  ///
  public func draw(in view: MTKView) {
    
    // create a Command Buffer & Encoder
    guard let buffer = _commandQueue.makeCommandBuffer() else { fatalError("Unable to create a Command Queue") }
    guard let desc = view.currentRenderPassDescriptor else { fatalError("Unable to create a Render Pass Descriptor") }
    guard let encoder = buffer.makeRenderCommandEncoder(descriptor: desc) else { fatalError("Unable to create a Command Encoder") }

    encoder.pushDebugGroup("Draw")
    
    // set the pipeline state
    encoder.setRenderPipelineState(_pipelineState)
    
    // bind the Intensity & Constant buffers
    encoder.setVertexBuffer(_intensityBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(_lineBuffer, offset: 0, index: 1)
    encoder.setVertexBytes(&_constant, length: MemoryLayout<Constant>.size, index: 2)
    
    // bind the Gradient texture
    encoder.setFragmentTexture(_gradientTexture, index: 0)
    
    // bind the Gradient Sampler
    encoder.setFragmentSamplerState(_gradientSamplerState, index: 0)
    
    // Draw the line(s)
    for i in 0..<Int(view.frame.size.height) {
      // move to the next set of Intensities
      encoder.setVertexBufferOffset(i * MemoryLayout<Intensity>.stride * kMaxIntensities, index: 0)
      // move to the next set of Line params
      encoder.setVertexBufferOffset((i * MemoryLayout<Line>.stride), index: 1)
      // draw
      encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: kMaxIntensities)
    }
    
    // finish encoding commands
    encoder.endEncoding()
    
    // present the drawable to the screen
    buffer.present(view.currentDrawable!)
    
    // finalize rendering & push the command buffer to the GPU
    buffer.commit()
//    buffer.waitUntilCompleted()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func setConstants(size: CGSize) {
    
//    _numberOfVertices = kMaxIntensities
    _constant.blackLevel = UInt16((Float(_waterfall?.blackLevel ?? 10) / 100.0) * Float(UInt16.max))
    _constant.colorGain = UInt16(_waterfall?.colorGain ?? 20)
    _constant.offsetY = 0
    _constant.numberOfLines = UInt16(size.height)
    _constant.startingFrequency = Float(_start)
    _constant.endingFrequency = Float(_end)

    _topLine = 0
    
    Swift.print("constants = \(_constant)")
  }
  
  func setLevels(autoBlack: Bool, blackLevel: Int, colorGain: Int) {

    _constant.blackLevel = autoBlack ? UInt16(_autoBlackLevel) : UInt16( (Float(blackLevel) / 100.0) * Float(UInt16.max) )
    _constant.colorGain = UInt16(colorGain)
  }
  
  /// Setup persistent objects & state
  ///
  func setup(device: MTLDevice) {
    
//    makeTestData()
    
    _device = device
    
    makeIntensityBuffer(device: device)
    
    makeLineBuffer(device: device)
    
    makePipeline(device: device)
    
    makeGradient(device: device)
    
    makeCommandQueue(device: device)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
//  private func addBufferLine(line: Int) {
//
//    memcpy(_intensityBuffer.contents().advanced(by: line * MemoryLayout<Intensity>.stride * _numberOfVertices), &intensityTestData, MemoryLayout<Intensity>.size * _numberOfVertices)
//  }
  
  
  private func makeIntensityBuffer(device: MTLDevice) {
    
    // create the buffer
    let size = kMaxLines * kMaxIntensities * MemoryLayout<Intensity>.stride
    _intensityBuffer = device.makeBuffer(length: size, options: [.storageModeShared])
  }
  
  private func makeLineBuffer(device: MTLDevice) {
    
    // create the buffer
    let size = kMaxLines * MemoryLayout<Line>.stride
    _lineBuffer = device.makeBuffer(length: size, options: [.storageModeShared])
    
    for i in 0..<kMaxLines {
      _line.number = UInt16(i)
      // copy data to the Line buffer
      memcpy(_lineBuffer.contents().advanced(by: i * MemoryLayout<Line>.stride), &_line, MemoryLayout<Line>.size)
    }
  }
  
  private func makePipeline(device: MTLDevice) {
    
    // get the Library (contains all compiled .metal files in this project)
    let library = device.makeDefaultLibrary()
    
    // are the vertex & fragment shaders in the Library?
    guard let vertexShader = library?.makeFunction(name: kVertexShader), let fragmentShader = library?.makeFunction(name: kFragmentShader) else {
      fatalError("Unable to find shader function(s) - \(kVertexShader) or \(kFragmentShader)")
    }
    // create the Render Pipeline State object
    let pipelineDesc = MTLRenderPipelineDescriptor()
    pipelineDesc.vertexFunction = vertexShader
    pipelineDesc.fragmentFunction = fragmentShader
    pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
    _pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
  }
  
  private func makeGradient(device: MTLDevice) {
    
    // define a 1D texture for a Gradient
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.textureType = .type1D
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = kGradientSize
    textureDescriptor.usage = [.shaderRead]
    _gradientTexture = device.makeTexture(descriptor: textureDescriptor)
    
    // create a gradient Sampler state
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.sAddressMode = .clampToEdge
    samplerDescriptor.tAddressMode = .clampToEdge
    samplerDescriptor.minFilter = .nearest
    samplerDescriptor.magFilter = .nearest
    _gradientSamplerState = device.makeSamplerState(descriptor: samplerDescriptor)
  }
  
  private func makeCommandQueue(device: MTLDevice) {
    
    // create a Command Queue object
    _commandQueue = device.makeCommandQueue()
  }
  
  
  func setGradient(_ array: [UInt8]) {
    // copy the Gradient data into the texture
    let region = MTLRegionMake1D(0, kGradientSize)
    _gradientTexture!.replace(region: region, mipmapLevel: 0, withBytes: array, bytesPerRow: kGradientSize * MemoryLayout<Float>.size)
    
  }
  
//  private func makeTestData() {
//
//    let incr = Int( (1.0 / Float(_numberOfVertices) ) * Float(UInt16.max))
//    for i in 0..<_numberOfVertices {
//      intensityTestData.append(Intensity(i: UInt16(i * incr) ))
//    }
//  }
}

// ----------------------------------------------------------------------------
// MARK: - WaterfallStreamHandler protocol methods
//

extension WaterfallRenderer                 : StreamHandler {
  
  //  frame Layout: (see xLib6000 WaterfallFrame)
  //
  //  public var firstBinFreq: CGFloat                        // Frequency of first Bin in Hz
  //  public var binBandwidth: CGFloat                        // Bandwidth of a single bin in Hz
  //  public var lineDuration: Int                            // Duration of this line in ms (1 to 100)
  //  public var lineHeight: Int                              // Height of frame in pixels
  //  public var autoBlackLevel: UInt32                       // Auto black level
  //  public var numberOfBins: Int                            // Number of bins
  //  public var bins: [UInt16]                               // Array of bin values
  //
  
  /// Process the UDP Stream Data for the Waterfall
  ///
  ///   StreamHandler protocol, executes on the streamQ
  ///
  /// - Parameter streamFrame:        a Waterfall frame
  ///
  public func streamHandler<T>(_ streamFrame: T) {
    
    guard let streamFrame = streamFrame as? WaterfallFrame else { return }

    _autoBlackLevel = streamFrame.autoBlackLevel
    
    // copy the Intensities into the Intensity buffer
    let binsPtr = UnsafeRawPointer(streamFrame.bins).bindMemory(to: UInt8.self, capacity: streamFrame.totalBins * MemoryLayout<UInt16>.size)
    memcpy(_intensityBuffer.contents().advanced(by: Int(_topLine) * MemoryLayout<Intensity>.stride * kMaxIntensities), binsPtr, streamFrame.numberOfBins * MemoryLayout<UInt16>.size)

    if _topLine == 0 {
      _topLine = UInt16(_constant.numberOfLines - 1)
    } else {
      _topLine -= 1
    }    
    // update the Waterfall's Starting & Ending frequency
    _constant.startingFrequency = Float(_start)
    _constant.endingFrequency = Float(_end)
    
    // copy the First Bin Frequency & Bin Bandwidth for this line
    var firstBinFrequency = Float(streamFrame.firstBinFreq)
    var binBandWidth = Float(streamFrame.binBandwidth)
    memcpy(_lineBuffer.contents().advanced(by: Int(_topLine) * MemoryLayout<Line>.stride), &firstBinFrequency, MemoryLayout<Float>.size)
    memcpy(_lineBuffer.contents().advanced(by: Int(_topLine) * MemoryLayout<Line>.stride + MemoryLayout<Float>.stride), &binBandWidth, MemoryLayout<Float>.size)

    _waterDrawQ.async { [unowned self] in
      autoreleasepool {
       self._metalView.draw()
      }
    }

    if _constant.offsetY == _constant.numberOfLines - 1 {
      _constant.offsetY = 0
    } else {
      _constant.offsetY += 1
    }
  }
}
