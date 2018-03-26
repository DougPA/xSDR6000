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

public final class WaterfallRenderer: NSObject {
  
  
  
  //  NOTE:
  //
  //  The intensity values are expected to be UInt16's between zero and UInt16.max.
  //
  //  The Radio sends an array of size ??? (larger than frame.width). The portion of the
  //  data, corresponding to the starting through ending frequency, of the Panadapter is
  //  determined based on the dataFrame.firstBinFreq and the dataFrame.binBandwidth.
  //
  //  The intensity values (in _intensityTexture) are converted into color values
  //  derived from a color gradient and placed into the _drawtexture.
  //
  //  Two triangles are drawn to make a rectangle covering the waterfall and the _drawTexture
  //  is superimposed over that rectangle.
  //
  //  The _drawTexture is used in a way that simulates scrolling so that the waterfall
  //  scrolls down. The texture is configured to wrap (top to bottom).
  //
  //  All of the incoming intensity values are processed but only the visible portion is
  //  displayed because of the clip space conversion (texture values with coordinates
  //  outside of the 0.0 to 1.0 range are ignored).
  //
  
  
  //  Vertices    v1  (-1, 1)     |     ( 1, 1)  v3       Texture     v1  ( 0, 0) |---------  ( 1, 0)  v3
  //  (-1 to +1)                  |                       (0 to 1)                |
  //                          ----|----                                           |
  //                              |                                               |
  //              v0  (-1,-1)     |     ( 1,-1)  v2                   v0  ( 0, 1) |           ( 1, 1)  v2
  //
  //  NOTE:   texture coords are recalculated based on screen size and startingBin / endingBin
  //
  
  
  //      Screen                                              Texture
  //  ------------------   ^                      ---------------------------------   ^
  //  |                |   |                      |                               |   |
  //  |                |   | frameHeight          |                               |   |
  //  |                |   |                      |                               |   |
  //  |                |   |          topIndex->  |       ------------------      |   | textureHeight
  //  |                |   |                      |              ^                |   |
  //  ------------------   V                      |              |                |   |
  //                                              |              | frameHeight    |   |
  //                                              |              |                |   |
  //                                              |              V                |   |
  //                               bottomIndex->  |       ------------------      |   |
  //                                              |                               |   |
  //                                              |                               |   |
  //                                              ---------------------------------   V
  //                                                      ^                 ^
  //                                                      |                 |
  //                                                  startingBin         EndingBin
  //
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  var metalView                             : MTKView?
  var updateNeeded                          = true                          // true == recalc texture coords
  
  struct Vertex {
    var coord                               : float2                        // waterfall coordinates
    var texCoord                            : float2                        // texture coordinates
  }
  
  struct Constants {
    var blackLevel                          : UInt16                        // black level
    var colorGain                           : Float                         // color gain, 0.0 -> 1.0
    var lineNumber                          : UInt32                        // line in Texture
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  var radio: Radio?                         = Api.sharedInstance.radio
  weak var panadapter                       : Panadapter?
  private weak var _waterfall               : Waterfall? { return radio!.waterfalls[panadapter!.waterfallId] }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _center                       : Int {return panadapter!.center }
  private var _bandwidth                    : Int { return panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  
  private var _waterfallVertices              : [Vertex] = [
    Vertex(coord: float2(-1.0, -1.0), texCoord: float2( 0.0, 1.0)),         // v0 - bottom left
    Vertex(coord: float2(-1.0,  1.0), texCoord: float2( 0.0, 0.0)),         // v1 - top    left
    Vertex(coord: float2( 1.0, -1.0), texCoord: float2( 1.0, 1.0)),         // v2 - bottom right
    Vertex(coord: float2( 1.0,  1.0), texCoord: float2( 1.0, 0.0))          // v3 - top    right
  ]
  
  private var _waterfallVerticesLength      = 0
  
  private var _metalView                    : MTKView!
  private var _device                       : MTLDevice!
  
  private var _constants                    = Constants(blackLevel: 0, colorGain: 0.0, lineNumber: 0 )
  private var _constantsBuffer              : MTLBuffer!
  
  private var _waterfallPipelineState       : MTLRenderPipelineState!       // render pipeline state
  private var _computePipelineState         : MTLComputePipelineState!      // compute pipeline state
  private var _gradientSamplerState         : MTLSamplerState!              // sampler for gradient
  
  private var _colorTexture                 : MTLTexture!                   //
  private var _gradientTexture              : MTLTexture!                   // color gradient
  private var _intensityTextures            = [MTLTexture]()                // intensities array
  
  private var _samplerState                 : MTLSamplerState!              // sampler for draw texture
  private var _commandQueue                 : MTLCommandQueue!              // Metal queue
  
  // macOS 10.13
  private var _threadsPerThreadgroup        : MTLSize!
  private var _threadsPerGrid               : MTLSize!
  
  // macOS 10.11 -> arbitrary choice - may be tunable to improve performance on various Mac hardware
  let _threadGroupCount                     = MTLSizeMake(16, 16, 1)        // parameters for GPU compute
  lazy var _threadGroups: MTLSize           = {
    MTLSizeMake(WaterfallRenderer.kTextureWidth / self._threadGroupCount.width, WaterfallRenderer.kTextureHeight / self._threadGroupCount.height, 1)
  }()
  
  private var _textureTopLine               = 0                             // current top Line in _drawTexture
  
  private var _firstBinFreq                 : CGFloat = 0                   // Frequency of first Bin in Hz
  private var _binBandwidth                 : CGFloat = 0                   // Bandwidth of a single bin in Hz
  private var _autoBlackLevel               : UInt16 = 0                    // Blacklevel supplied by Radio
  
  private var _frameBoundarySemaphore       = DispatchSemaphore(value: WaterfallRenderer.kMaxTextures)
  private let _waterQ                       = DispatchQueue(label: ".waterQ", attributes: [.concurrent])
  
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  //
  private var __frameSize                     = CGSize(width: 0.0, height: 0.0)
  private var __textureIndex                  = 0                             // mod kMaxTextures
  //
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  
  private var _frameSize: CGSize {
    get { return _waterQ.sync { __frameSize } }
    set { _waterQ.sync( flags: .barrier){ __frameSize = newValue } } }
  
  private var _textureIndex: Int {
    get { return _waterQ.sync { __textureIndex } }
    set { _waterQ.sync( flags: .barrier){ __textureIndex = newValue } } }
  
  // constants
  private let kWaterfallVertex              = "waterfall_vertex"            // name of waterfall vertex function
  private let kWaterfallFragment            = "waterfall_fragment"          // name of waterfall fragment function
  private let kComputeGradient              = "convert"                     // name of waterfall kernel function
  
  // values chosen to accomodate the largest possible waterfall
  static let kTextureWidth                  = 3360                          // must be >= max number of Bins
  static let kTextureHeight                 = 2048                          // must be >= max number of lines
  static let kMaxTextures                   = 3                             // number of Intensity textures
  
  // arbitrary choice of a reasonable number of color gradations for the waterfall
  static let kGradientSize                  = 256                           // number of colors in a gradient
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(view: MTKView, clearColor color: NSColor) {
    
    _metalView = view
    
    // save the Metal device
    _metalView.device = MTLCreateSystemDefaultDevice()
    _device = _metalView.device
    
    // configure the Metal view to be drawn on demand only
    _metalView.isPaused = true
    _metalView.enableSetNeedsDisplay = false
    
    super.init()
    
    // set the Metal view Clear color
    clearColor(color)
    
    // create all of the objects
    setupPersistentObjects()
    
    view.delegate = self
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Copy constants to the Constants Buffer
  ///
  func updateConstants(autoBlack: Bool, blackLevel: Int, colorGain: Int) {
    
    let blackLevel = ( autoBlack ? _autoBlackLevel : UInt16( Float(blackLevel)/100.0 * Float(UInt16.max) ))
    
    _constants.blackLevel = blackLevel
    _constants.colorGain = Float(colorGain)/100.0
    _constants.lineNumber = UInt32(_textureTopLine)
    
    // Mapping of the Constants struct
    //  <------ 16 ------>                      blackLevel
    //  <--------------- 32 ---------------->   colorGain
    //  <--------------- 32 ---------------->   lineNumber
    
    // update the Constants buffer
    //      NOTE: simple copy, only possible due to the arrangement of the struct with no padding
    ///
    let bufferPtr = _constantsBuffer!.contents()
    memcpy(bufferPtr, &_constants, MemoryLayout.stride(ofValue: _constants))
  }  
  /// Re-initialize the Waterfall
  ///
  func restart() {
    
    // force the waterfall to initialize the texture usage
    _textureTopLine = 0
    _binBandwidth = 0
    _firstBinFreq = 0
  }
  /// Set the Metal view clear color
  ///
  /// - Parameter color:        an NSColor
  ///
  func clearColor(_ color: NSColor) {
    _metalView.clearColor = MTLClearColor(red: Double(color.redComponent),
                                          green: Double(color.greenComponent),
                                          blue: Double(color.blueComponent),
                                          alpha: Double(color.alphaComponent) )
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Setup persistent objects & state
  ///
  func setupPersistentObjects() {
    
    // define a 1D texture for a Gradient
    let gradientTextureDescriptor = MTLTextureDescriptor()
    gradientTextureDescriptor.textureType = .type1D
    gradientTextureDescriptor.pixelFormat = .bgra8Unorm
    gradientTextureDescriptor.width = WaterfallRenderer.kGradientSize
    gradientTextureDescriptor.usage = [.shaderRead]
    
    // create a 1D Gradient texture
    _gradientTexture = _device.makeTexture(descriptor: gradientTextureDescriptor)
    
    // define a 2D texture for Colors
    let colorTextureDescriptor = MTLTextureDescriptor()
    colorTextureDescriptor.textureType = .type2D
    colorTextureDescriptor.pixelFormat = .bgra8Unorm
    colorTextureDescriptor.width = WaterfallRenderer.kTextureWidth
    colorTextureDescriptor.height = WaterfallRenderer.kTextureHeight
    colorTextureDescriptor.usage = [.shaderRead, .shaderWrite]
    
    // create a 2D Color texture
    _colorTexture = _device.makeTexture(descriptor: colorTextureDescriptor)
    
    // define a 1D texture for Intensities
    let intensityTextureDescriptor = MTLTextureDescriptor()
    intensityTextureDescriptor.textureType = .type1D
    intensityTextureDescriptor.pixelFormat = .r16Uint
    intensityTextureDescriptor.width = WaterfallRenderer.kTextureWidth
    intensityTextureDescriptor.usage = [.shaderRead, .shaderWrite]
    
    // populate the array of Intensity textures
    for _ in 0..<WaterfallRenderer.kMaxTextures {
      // create an Intensity texture
      let intensityTexture = _device.makeTexture(descriptor: intensityTextureDescriptor)!
      // append it to the array of Textures
      _intensityTextures.append( intensityTexture )
    }
    
    // get the Library (contains all compiled .metal files in this project)
    let library = _device.makeDefaultLibrary()
    
    // are the vertex & fragment shaders in the Library?
    if let waterfallVertex = library?.makeFunction(name: kWaterfallVertex), let waterfallFragment = library?.makeFunction(name: kWaterfallFragment) {
      
      // YES, create a Render Pipeline Descriptor for the Waterfall
      let waterfallPipelineDesc = MTLRenderPipelineDescriptor()
      waterfallPipelineDesc.vertexFunction = waterfallVertex
      waterfallPipelineDesc.fragmentFunction = waterfallFragment
      waterfallPipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
      
      // create and save the Render Pipeline State object
      _waterfallPipelineState = try! _device.makeRenderPipelineState(descriptor: waterfallPipelineDesc)
      
    } else {
      
      // NO, crash
      fatalError("Unable to find shader function(s) - \(kWaterfallVertex) or \(kWaterfallFragment)")
    }
    
    // create the Uniforms buffer
    _constantsBuffer = _device.makeBuffer(length: MemoryLayout.stride(ofValue: _constants))
    
    // create and save a Command Queue object
    _commandQueue = _device.makeCommandQueue()
    _commandQueue.label = "Waterfall"
    
    // create a waterfall Sampler Descriptor & set its parameters
    let waterfallSamplerDescriptor = MTLSamplerDescriptor()
    waterfallSamplerDescriptor.sAddressMode = .repeat
    waterfallSamplerDescriptor.tAddressMode = .repeat
    waterfallSamplerDescriptor.minFilter = .nearest
    waterfallSamplerDescriptor.magFilter = .nearest
    
    // create and save a Sampler State
    _samplerState = _device.makeSamplerState(descriptor: waterfallSamplerDescriptor)
    
    // is the compute shader in the Library
    if let kernelFunction = library?.makeFunction(name: kComputeGradient) {
      
      // YES, create and save the Compute Pipeline State object
      _computePipelineState = try! _device.makeComputePipelineState(function: kernelFunction)
      
      let w = _computePipelineState.threadExecutionWidth
      let h = _computePipelineState.maxTotalThreadsPerThreadgroup / w
      _threadsPerThreadgroup = MTLSizeMake(w, h, 1)
      
      _threadsPerGrid = MTLSize(width: _intensityTextures[0].width,
                                height: _intensityTextures[0].height,
                                depth: 1)
    } else {
      
      // NO, crash
      fatalError("Unable to find shader function - \(kComputeGradient)")
    }
    
    // create a gradient Sampler Descriptor & set its parameters
    let gradientSamplerDescriptor = MTLSamplerDescriptor()
    gradientSamplerDescriptor.sAddressMode = .clampToEdge
    gradientSamplerDescriptor.tAddressMode = .clampToEdge
    gradientSamplerDescriptor.minFilter = .nearest
    gradientSamplerDescriptor.magFilter = .nearest
    
    // create and save a Gradient Sampler State
    _gradientSamplerState = _device.makeSamplerState(descriptor: gradientSamplerDescriptor)
    
    _waterfallVerticesLength = MemoryLayout<Vertex>.stride * _waterfallVertices.count
  }
  /// Copy a gradient array to the gradient Texture
  ///
  /// - Parameter gradient:   an array of BGRA8Unorm values
  ///
  func setGradient(_ gradient: [UInt8]) {
    
    // make a region that encompasses the gradient
    let region = MTLRegionMake1D(0, WaterfallRenderer.kGradientSize)
    
    // copy the Gradient into the current texture
    _gradientTexture!.replace(region: region, mipmapLevel: 0, withBytes: gradient, bytesPerRow: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
  }
}

// ----------------------------------------------------------------------------
// MARK: - MTKViewDelegate protocol methods

extension WaterfallRenderer                 : MTKViewDelegate {
  
  /// Respond to a change in the size of the MTKView
  ///
  /// - Parameters:
  ///   - view:         the MetalKit View
  ///   - size:         its new size
  ///
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
    // capture the new size
    _frameSize = size
  }
  
  /// Draw a rectangle over the Waterfall area and texture it with the converted Intensities
  ///
  /// - Parameter view:         a MetalKit View
  ///
  public func draw(in view: MTKView) {
    
    autoreleasepool {
      
      // obtain a Command buffer & a Render Pass descriptor
      guard let cmdBuffer = self._commandQueue.makeCommandBuffer(),
        let descriptor = view.currentRenderPassDescriptor else { return }
      
      // create a Compute encoder
      let computeEncoder = cmdBuffer.makeComputeCommandEncoder()!
      
      computeEncoder.pushDebugGroup("Compute")
      
      // set the pipeline state
      computeEncoder.setComputePipelineState(self._computePipelineState)
      
      // choose and bind the input Texture
      computeEncoder.setTexture(self._intensityTextures[self._textureIndex], index: 0)
      
      // bind the output Texture
      computeEncoder.setTexture(self._colorTexture, index: 1)
      
      // bind the Gradient texture
      computeEncoder.setTexture(self._gradientTexture, index: 2)
      
      // bind the Constants buffer
      computeEncoder.setBuffer(self._constantsBuffer, offset: 0, index: 0)
      
      // bind the Sampler state
      computeEncoder.setSamplerState(self._gradientSamplerState, index: 0)
      
      // perform the computation
      if #available(OSX 10.13, *) {
        computeEncoder.dispatchThreads(self._threadsPerGrid, threadsPerThreadgroup: self._threadsPerThreadgroup)
      } else {
        // Fallback on earlier versions
        computeEncoder.dispatchThreadgroups(self._threadGroups, threadsPerThreadgroup: self._threadGroupCount)
      }
      computeEncoder.popDebugGroup()
      
      // finish encoding
      computeEncoder.endEncoding()
      
      // set Load & Store actions
      descriptor.colorAttachments[0].loadAction = .dontCare
      descriptor.colorAttachments[0].storeAction = .store
      
      // create a Render encoder
      let renderEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
      renderEncoder.pushDebugGroup("Draw")
      
      // set the pipeline state
      renderEncoder.setRenderPipelineState(self._waterfallPipelineState)
      
      // bind the vertices
      renderEncoder.setVertexBytes(UnsafeRawPointer(self._waterfallVertices), length: self._waterfallVerticesLength, index: 0)
      
      // bind the Color texture
      renderEncoder.setFragmentTexture(self._colorTexture, index: 0)
      
      // bind the Sampler state
      renderEncoder.setFragmentSamplerState(self._samplerState, index: 0)
      
      // Draw the triangles
      renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      
      // finish encoding
      renderEncoder.endEncoding()
      
      renderEncoder.popDebugGroup()
      
      // present the drawable to the screen
      cmdBuffer.present(self._metalView.currentDrawable!)
      
      // signal on completion
      cmdBuffer.addCompletedHandler() { _ in self._frameBoundarySemaphore.signal() }
      
      // push the command buffer to the GPU
      cmdBuffer.commit()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - WaterfallStreamHandler protocol methods
//

extension WaterfallRenderer                 : WaterfallStreamHandler {
  
  //  dataFrame Struct Layout: (see xLib6000 WaterfallFrame)
  //
  //  public var firstBinFreq: CGFloat                        // Frequency of first Bin in Hz
  //  public var binBandwidth: CGFloat                        // Bandwidth of a single bin in Hz
  //  public var lineDuration: Int                            // Duration of this line in ms (1 to 100)
  //  public var lineHeight: Int                              // Height of frame in pixels
  //  public var autoBlackLevel: UInt32                       // Auto black level
  //  public var numberOfBins: Int                            // Number of bins
  //  public var bins: [UInt16]                               // Array of bin values
  //
  
  /// Process the UDP Stream Data for the Waterfall (called on the waterfallQ)
  ///
  /// - Parameter dataFrame:  a waterfall dataframe struct
  ///
  public func waterfallStreamHandler(_ dataframe: WaterfallFrame ) {
    
    // wait for an available Intensity Texture
    _frameBoundarySemaphore.wait()
    
    // set the index to the next Intensity Texture
    _textureIndex = (_textureIndex + 1) % WaterfallRenderer.kMaxTextures
    
    // recalc values initially or when center/bandwidth changes
    if dataframe.binBandwidth != _binBandwidth || dataframe.firstBinFreq != _firstBinFreq {
      
      // calculate the starting & ending bin numbers
      let startingBin = Float( (CGFloat(_start) - dataframe.firstBinFreq) / dataframe.binBandwidth )
      let endingBin = Float( (CGFloat(_end) - dataframe.firstBinFreq) / dataframe.binBandwidth )
      
      // set the texture left edge (in clip space, i.e. 0.0 to 1.0)
      let leftSide = startingBin / Float(WaterfallRenderer.kTextureWidth - 1)
      _waterfallVertices[0].texCoord.x = leftSide                     // clip space value for bottom left x
      _waterfallVertices[1].texCoord.x = leftSide                     // clip space value for top left x
      
      // set the texture right edge (in clip space, i.e. 0.0 to 1.0)
      let rightSide = endingBin / Float(WaterfallRenderer.kTextureWidth - 1)
      _waterfallVertices[2].texCoord.x = rightSide                    // clip space value for bottom right x
      _waterfallVertices[3].texCoord.x = rightSide                    // clip space value for top right x
    }
    // record the current values
    _autoBlackLevel = UInt16(dataframe.autoBlackLevel)
    _binBandwidth = dataframe.binBandwidth
    _firstBinFreq = dataframe.firstBinFreq
    
    // set y coordinates of the top of the texture (in clip space, i.e. 0.0 to 1.0)
    let topIndex = Float(_textureTopLine)                                 // index into texture
    let topSide = topIndex / Float(WaterfallRenderer.kTextureHeight - 1)   // clip space value for index
    _waterfallVertices[3].texCoord.y = topSide                          // clip space value for top right y
    _waterfallVertices[1].texCoord.y = topSide                          // clip space value for top left y
    
    // set y coordinates of the bottom of the texture (in clip space, i.e. 0.0 to 1.0)
    let bottomIndex = Float(_textureTopLine) + Float(_frameSize.height - 1)    // index into texture
    let bottomSide = bottomIndex / Float(WaterfallRenderer.kTextureHeight - 1) // clip space value for index
    _waterfallVertices[2].texCoord.y = bottomSide                       // clip space value for bottom right y
    _waterfallVertices[0].texCoord.y = bottomSide                       // clip space value for bottom left y
    
    // set the Uniforms
    updateConstants(autoBlack: _waterfall!.autoBlackEnabled, blackLevel: _waterfall!.blackLevel, colorGain: _waterfall!.colorGain )
    
    // copy the Intensities into the current texture
    let binsPtr = UnsafeRawPointer(dataframe.bins).bindMemory(to: UInt8.self, capacity: dataframe.numberOfBins * MemoryLayout<UInt16>.size)
    let region = MTLRegionMake1D(0, dataframe.numberOfBins)
    _intensityTextures[_textureIndex].replace(region: region, mipmapLevel: 0, withBytes: binsPtr, bytesPerRow: WaterfallRenderer.kTextureWidth * MemoryLayout<UInt16>.size)
    
    // decrement the texture line that is used as the "top" line of the display
    _textureTopLine = ( _textureTopLine == 0 ? WaterfallRenderer.kTextureHeight - 1 : _textureTopLine - 1 )
    
    DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
      self._metalView.draw()
    }
  }
}
