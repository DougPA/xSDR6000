//
//  PanadapterRenderer.swift
//  xSDR6000
//
//  Created by Douglas Adams on 9/30/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation
import MetalKit
import xLib6000

public final class PanadapterRenderer       : NSObject {
  
  //  As input, the renderer expects an array of UInt16 intensity values. The intensity values are
  //  scaled by the radio to be between zero and Panadapter.yPixels. The values are inverted
  //  i.e. the value of Panadapter.yPixels is zero intensity and a value of zero is maximum intensity.
  //  The Panadapter sends an array of size Panadapter.xPixels (same as frame.width).
  //
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kMaxIntensities                = 3_072                         // max number of intensity values (bins)
  static let kTextureAsset                  = "1x16"                        // name of the texture asset
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  private struct SpectrumValue {
    var i                                   : ushort                        // intensity
  }
  
  private struct Constants {
    var delta                               : Float                         // distance between x coordinates
    var height                              : Float                         // height of view (yPixels)
    var maxNumberOfBins                     : UInt32                        // number of DataFrame bins
  }
  private struct Color {
    var spectrumColor                       : float4                        // spectrum / fill color
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _metalView                    : MTKView!
  private var _device                       : MTLDevice!
  
  private var _spectrumValues               = [UInt16](repeating: 0, count: PanadapterRenderer.kMaxIntensities * 2)
  private var _spectrumBuffers              = [MTLBuffer]()
  private var _spectrumIndices              = [UInt16](repeating: 0, count: PanadapterRenderer.kMaxIntensities * 2)
  private var _spectrumIndicesBuffer        : MTLBuffer!
  
  private var _maxNumberOfBins              : Int = PanadapterRenderer.kMaxIntensities
  
  private var _constants                    : Constants?
  private var _colorArray                   = [Color](repeating: Color(spectrumColor: NSColor.yellow.float4Color), count: 2)
  
  private var _commandQueue                 : MTLCommandQueue!
  private var _pipelineState                : MTLRenderPipelineState!
  
  private var _fillLevel                    = 1
  
  private var _frameBoundarySemaphore       = DispatchSemaphore(value: kNumberSpectrumBuffers)
  private let _panQ                         = DispatchQueue(label: ".panQ", attributes: [.concurrent])
  
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  //
  private var __currentFrameIndex           = 0
  private var __numberOfBins                : Int = PanadapterRenderer.kMaxIntensities
  //
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  
  private var _currentFrameIndex: Int {
    get { return _panQ.sync { __currentFrameIndex } }
    set { _panQ.sync( flags: .barrier){ __currentFrameIndex = newValue } } }
  
  private var _numberOfBins: Int {
    get { return _panQ.sync { __numberOfBins } }
    set { _panQ.sync( flags: .barrier){ __numberOfBins = newValue } } }
  
  // constants
  private let _log                          = (NSApp.delegate as! AppDelegate)
  private let kPanadapterVertex             = "panadapter_vertex"
  private let kPanadapterFragment           = "panadapter_fragment"
  private let kSpectrumBufferIndex          = 0
  private let kConstantsBufferIndex         = 1
  private let kColorBufferIndex             = 2
  
  private let kFillColor                    = 0
  private let kLineColor                    = 1
  
  private static let kNumberSpectrumBuffers = 3
  
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
  // MARK: - Internal methods
  
  func updateConstants(size: CGSize) {
    // Constants struct mapping
    //  <--- 4 ---> <--- 4 ---> <--- 4 ---> <-- empty -->              delta height maxNumberOfBins
    
    // does the struct exist?
    if _constants == nil {
      
      // NO, create it
      _constants = Constants(delta: Float(1.0 / (size.width - 1.0)),
                             height: Float(size.height),
                             maxNumberOfBins: UInt32(_maxNumberOfBins))
    } else {
      // YES, populate it
      _constants!.delta = Float(1.0 / (size.width - 1.0))
      _constants!.height = Float(size.height)
      _constants!.maxNumberOfBins = UInt32(_maxNumberOfBins)
    }
  }
  
  func updateColor(spectrumColor: NSColor, fillLevel: Int, fillColor: NSColor) {
    // Color struct mapping
    //  <--------------------- 16 ---------------------->              spectrumColor
    
    _fillLevel = fillLevel
    
    // calculate the effective fill color
    let fillPercent = CGFloat(fillLevel)/CGFloat(100.0)
    let adjFillColor = NSColor(red: fillColor.redComponent * fillPercent,
                               green: fillColor.greenComponent * fillPercent,
                               blue: fillColor.blueComponent * fillPercent,
                               alpha: fillColor.alphaComponent * fillPercent)
    
    // update the array
    _colorArray[kFillColor].spectrumColor = adjFillColor.float4Color
    _colorArray[kLineColor].spectrumColor = spectrumColor.float4Color
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
  // MARK: - Private methods
  
  /// Setup Objects, Buffers & State
  ///
  private func setupPersistentObjects() {
    
    // create and populate Spectrum buffers
    let dataSize = _spectrumValues.count * MemoryLayout.stride(ofValue: _spectrumValues[0])
    for _ in 0..<PanadapterRenderer.kNumberSpectrumBuffers {
      _spectrumBuffers.append(_device.makeBuffer(bytes: _spectrumValues, length: dataSize, options: [.storageModeShared])!)
    }
    
    // populate the Indices array used for style == .fill || style == .fillWithTexture
    for i in 0..<PanadapterRenderer.kMaxIntensities {
      // n,0,n+1,1,...2n-1,n-1
      _spectrumIndices[2 * i] = UInt16(PanadapterRenderer.kMaxIntensities + i)
      _spectrumIndices[(2 * i) + 1] = UInt16(i)
    }
    
    // create and populate an Indices buffer (for filled drawing only)
    let indexSize = _spectrumIndices.count * MemoryLayout.stride(ofValue: _spectrumIndices[0])
    _spectrumIndicesBuffer = _device.makeBuffer(bytes: _spectrumIndices, length: indexSize, options: [.storageModeShared])
    
    // get the Shaders library
    let library = _device.makeDefaultLibrary()!
    
    // create a Render Pipeline descriptor
    let rpd = MTLRenderPipelineDescriptor()
    rpd.vertexFunction = library.makeFunction(name: kPanadapterVertex)
    rpd.fragmentFunction = library.makeFunction(name: kPanadapterFragment)
    rpd.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    // create the Render Pipeline State object
    _pipelineState = try! _device.makeRenderPipelineState(descriptor: rpd)
    
    // create and save a Command Queue object
    _commandQueue = _device.makeCommandQueue()
    _commandQueue.label = "Panadapter"    
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Class methods
  
  /// Create a Texture from an image in the Assets.xcassets
  ///
  /// - Parameters:
  ///   - name:       name of the asset
  ///   - device:     a Metal Device
  /// - Returns:      a MTLTexture
  /// - Throws:       Texture loader error
  ///
  class func texture(forDevice device: MTLDevice, asset name: String) throws -> MTLTexture {
    
    // get a Texture loader
    let textureLoader = MTKTextureLoader(device: device)
    
    // identify the asset containing the image
    let asset = NSDataAsset.init(name: NSDataAsset.Name(rawValue: name))
    
    if let data = asset?.data {
      
      // if found, create the texture
      return try textureLoader.newTexture(data: data)
    } else {
      
      // image not found
      fatalError("Could not load image \(name) from an asset catalog in the main bundle")
    }
  }
  /// Create a Sampler State
  ///
  /// - Parameters:
  ///   - device:         a MTLDevice
  ///   - addressMode:    the desired Sampler address mode
  ///   - filter:         the desired Sampler filtering
  /// - Returns:          a MTLSamplerState
  ///
  class func samplerState(forDevice device: MTLDevice,
                          addressMode: MTLSamplerAddressMode,
                          filter: MTLSamplerMinMagFilter) -> MTLSamplerState {
    
    // create a Sampler Descriptor
    let samplerDescriptor = MTLSamplerDescriptor()
    
    // set its parameters
    samplerDescriptor.sAddressMode = addressMode
    samplerDescriptor.tAddressMode = addressMode
    samplerDescriptor.minFilter = filter
    samplerDescriptor.magFilter = filter
    
    // return the Sampler State
    return device.makeSamplerState(descriptor: samplerDescriptor)!
  }
}

// ----------------------------------------------------------------------------
// MARK: - MTKViewDelegate protocol methods

extension PanadapterRenderer                : MTKViewDelegate {
  
  /// Respond to a change in the size of the MTKView
  ///
  /// - Parameters:
  ///   - view:             the MTKView
  ///   - size:             its new size
  ///
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    // not used
  }
  /// Draw in the MTKView
  ///
  /// - Parameter view:     the MTKView
  ///
  public func draw(in view: MTKView) {
    
    autoreleasepool {
      
      // obtain a Command buffer & a Render Pass descriptor
      guard let cmdBuffer = self._commandQueue.makeCommandBuffer(),
        let descriptor = view.currentRenderPassDescriptor else { return }
      
      // Create a render encoder
      let encoder = cmdBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
      
      encoder.pushDebugGroup("Fill")
      
      // set the Spectrum pipeline state
      encoder.setRenderPipelineState(_pipelineState)
      
      // bind the active Spectrum buffer
      encoder.setVertexBuffer(_spectrumBuffers[_currentFrameIndex], offset: 0, index: kSpectrumBufferIndex)
      
      // bind the Constants
      encoder.setVertexBytes(&_constants, length: MemoryLayout.size(ofValue: _constants), index: kConstantsBufferIndex)
      
      // is the Panadapter "filled"?
      if self._fillLevel > 1 {
        
        // YES, bind the Fill Color
        encoder.setVertexBytes(&_colorArray[kFillColor], length: MemoryLayout.size(ofValue: _colorArray[kFillColor]), index: kColorBufferIndex)
        
        // Draw filled
        encoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: _numberOfBins * 2, indexType: .uint16, indexBuffer: _spectrumIndicesBuffer, indexBufferOffset: 0)
      }
      encoder.popDebugGroup()
      encoder.pushDebugGroup("Line")
      
      // bind the Line Color
      encoder.setVertexBytes(&_colorArray[kLineColor], length: MemoryLayout.size(ofValue: _colorArray[kLineColor]), index: kColorBufferIndex)
      
      // Draw as a Line
      encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: _numberOfBins)
      
      // finish using this encoder
      encoder.endEncoding()
      
      // present the drawable to the screen
      cmdBuffer.present(_metalView.currentDrawable!)
      
      // signal on completion
      cmdBuffer.addCompletedHandler() { _ in self._frameBoundarySemaphore.signal() }
      
      // push the command buffer to the GPU
      cmdBuffer.commit()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - PanadapterStreamHandler protocol methods

extension PanadapterRenderer                : PanadapterStreamHandler {


  //  DataFrame Layout: (see xLib6000 PanadapterFrame)
  //
  //  public var startingBinIndex: Int                    // Index of first bin
  //  public var numberOfBins: Int                        // Number of bins
  //  public var binSize: Int                             // Bin size in bytes
  //  public var frameIndex: Int                          // Frame index
  //  public var bins: [UInt16]                           // Array of bin values
  //
  
  /// Process the UDP Stream Data for the Panadapter (arrives on the streamQ)
  ///
  /// - Parameter frame:        a Panadapter frame
  ///
  public func streamHandler(_ frame: PanadapterFrame) {

    _frameBoundarySemaphore.wait()
    
    // move to using the next spectrumBuffer
    _currentFrameIndex = (_currentFrameIndex + 1) % PanadapterRenderer.kNumberSpectrumBuffers
    
    // dataFrame.numberOfBins is the number of horizontal pixels in the spectrum waveform
    _numberOfBins = frame.numberOfBins
    
    // put the Intensities into the current Spectrum Buffer
    _spectrumBuffers[_currentFrameIndex].contents().copyMemory(from: frame.bins, byteCount: frame.numberOfBins * MemoryLayout<ushort>.stride)
    
    DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
      self._metalView.draw()
    }
  }
}
