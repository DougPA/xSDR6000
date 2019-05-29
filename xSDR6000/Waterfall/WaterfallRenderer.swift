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
  
  //  The intensity values are expected to be UInt16's between zero and UInt16.max.
  //
  //  The Radio sends an array of size ??? (larger than frame.width). The portion of the
  //  data, corresponding to the starting through ending frequency, of the Panadapter is
  //  determined based on the dataFrame.firstBinFreq and the dataFrame.binBandwidth.
  //
  //  The intensity values (in _intensityTexture) are converted into color values
  //  derived from a color gradient.
  //
  //  All of the incoming intensity values are processed but only the visible portion is
  //  displayed because of the clip space conversion (values with coordinates
  //  outside of the 0.0 to 1.0 range are ignored).
  //
  
  
  //  Vertices    v1  (-1, 1)     |     ( 1, 1)  v3       Texture     v1  ( 0, 0) |---------  ( 1, 0)  v3
  //  (-1 to +1)                  |                       (0 to 1)                |
  //                          ----|----                                           |
  //                              |                                               |
  //              v0  (-1,-1)     |     ( 1,-1)  v2                   v0  ( 0, 1) |           ( 1, 1)  v2
  //

  // values chosen to accomodate the largest possible waterfall
  static let kMaxNumberOfIntensities        = 3360                          // must be >= max number of Bins
  static let kMaxNumberOfLines              = 2048                          // must be >= max number of lines
  
  // arbitrary choice of a reasonable number of color gradations for the waterfall
  static let kGradientSize                  = 256                           // number of colors in a gradient

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  var updateNeeded                          = true                          // true == recalc texture coords
  
  struct Intensity {
    var i                                   : UInt16 = 0                    // intensities
  }

  struct Constants {
    var deltaX                              : Float = 0.0                   // x incr between points
    var offsetY                             : UInt16 = 0                    //
    var numberOfLines                       : UInt16 = 0                    //
    var colorGain                           : Float = 0                     // color gain, 0.0 -> 1.0
    var blackLevel                          : UInt16 = 0                    // black level
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  var radio: Radio?                         = Api.sharedInstance.radio
  weak var panadapter                       : Panadapter?
  private weak var _waterfall               : Waterfall? { return radio!.waterfalls[panadapter!.waterfallId] }
  
  private var _center                       : Int {return panadapter!.center }
  private var _bandwidth                    : Int { return panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }

  private var _metalView                    : MTKView!
  private var _device                       : MTLDevice!
  private var _commandQueue                 : MTLCommandQueue!              // Metal queue
  private var _sizeOfLine                   = 0
  private var _sizeOfIntensities            = 0

  private var _intensityBuffer              : MTLBuffer!
  private var _pipelineState                : MTLRenderPipelineState!       // render pipeline state
  private var _gradientSamplerState         : MTLSamplerState!              // sampler for gradient
  private var _gradientTexture              : MTLTexture!                   // color gradient

  var intensityTestData                     : [Intensity]!
    

  
  
  private let _waterQ                       = DispatchQueue(label: ".waterQ", attributes: [.concurrent])
  private let _workerQ                      = DispatchQueue(label: Api.kId + ".waterfallWorkerQ")

  // constants
  private let kFragmentShader               = "waterfall_fragment"          // name of waterfall fragment function
  private let kVertexShader                 = "waterfall_vertex"            // name of waterfall vertex function

  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  //
  private var __constants                   = Constants()
  private var __frameSize                   = CGSize(width: 0.0, height: 0.0)
  private var __textureIndex                = 0                             // mod kMaxTextures
  private var __topLine                     : UInt16 = 0                    // line at top of waterfall

  private var __firstBinFreq                : CGFloat = 0                   // Frequency of first Bin in Hz
  private var __binBandwidth                : CGFloat = 0                   // Bandwidth of a single bin in Hz
  private var __autoBlackLevel              : UInt16 = 0                    // Blacklevel supplied by Radio
  //
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY -----------------------------------
  
  private var _constants : Constants {
    get { return _waterQ.sync { __constants } }
    set { _waterQ.sync(flags: .barrier) { __constants = newValue } }
  }
  private var _firstBinFreq: CGFloat {
    get { return _waterQ.sync { __firstBinFreq } }
    set { _waterQ.sync( flags: .barrier){ __firstBinFreq = newValue } } }
  
  private var _binBandwidth: CGFloat {
    get { return _waterQ.sync { __binBandwidth } }
    set { _waterQ.sync( flags: .barrier){ __binBandwidth = newValue } } }
  
  private var _autoBlackLevel: UInt16 {
    get { return _waterQ.sync { __autoBlackLevel } }
    set { _waterQ.sync( flags: .barrier){ __autoBlackLevel = newValue } } }
  
  private var _frameSize: CGSize {
    get { return _waterQ.sync { __frameSize } }
    set { _waterQ.sync( flags: .barrier){ __frameSize = newValue } } }
  
  private var _bufferNumber: Int {
    get { return _waterQ.sync { __textureIndex } }
    set { _waterQ.sync( flags: .barrier){ __textureIndex = newValue } } }

  private var _topLine: UInt16 {
    get { return _waterQ.sync { __topLine } }
    set { _waterQ.sync( flags: .barrier){ __topLine = newValue } } }

  // constants
  private let kWaterfallVertex              = "waterfall_vertex"            // name of waterfall vertex function
  private let kWaterfallFragment            = "waterfall_fragment"          // name of waterfall fragment function

// ------------ below here is questionable
  
  
  
  
  private var _waterfallVerticesLength      = 0
  private var _previousCenter               = 0
  private var _previousStart                = 0
  private var _previousEnd                  = 0

  private var _buffer                       = [Params]()                    // draw parameters array

  
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(view: MTKView, clearColor color: NSColor, autoBlack auto: Bool = false, blackLevel level: Int = 0, colorGain gain: Int = 0) {
    super.init()

    Swift.print("mtkview height = \(view.frame.height)")
    
    _metalView = view
    setConstants(size: view.frame.size)
    setup(view: view, clearColor: color)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Populate the Constants
  ///
  /// - Parameters:
  ///   - size:                 size of the frame
  ///   - autoBlack:            autoBlack enabled
  ///   - blackLevel:           black level
  ///   - colorGain:            color gain
  ///
  func setConstants(size: CGSize, autoBlack: Bool = false, blackLevel: Int = 0, colorGain: Int = 0) {
    
    let blackLevel = ( autoBlack ? _autoBlackLevel : UInt16( Float(blackLevel)/100.0 * Float(UInt16.max) ))
    
    _constants.blackLevel = blackLevel
    _constants.colorGain = Float(colorGain)/100.0
    _constants.deltaX = Float(1.0 / (Float(Int(size.width)) - 1.0))
    _constants.numberOfLines = UInt16(Int(size.height))
    _constants.offsetY = 0

//    Swift.print("""
//      deltaX = \(_constants.deltaX)
//      offsetY = \(_constants.offsetY)
//      numberOfLines = \(_constants.numberOfLines)
//      blackLevel = \(_constants.blackLevel)
//      colorGain = \(_constants.colorGain)
//      """
//    )
//    Swift.print("""
//      numberOfLines = \(_constants.numberOfLines)
//      """
//    )
  }
  /// Setup persistent objects & state
  ///
  /// - Parameters:
  ///   - view:                 the MTKView
  ///   - clearColor:           the clear color
  ///
  private func setup(view: MTKView, clearColor: NSColor) {
    
    // obtain the default Metal Device
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Unable to obtain a Metal Device")
    }
    view.device = device

    view.isPaused = true
    view.enableSetNeedsDisplay = false
    
    // set the Metal view Clear color
    view.clearColor = MTLClearColor(red: Double(clearColor.redComponent),
                                    green: Double(clearColor.greenComponent),
                                    blue: Double(clearColor.blueComponent),
                                    alpha: Double(clearColor.alphaComponent) )

    makeBuffers(device: device)
    
    makePipeline(device: device)
    
    makeGradient(device: device)
    
    makeCommandQueue(device: device)
    
    makeTestData()

    view.delegate = self
  }
  /// Create the buffers
  ///
  /// - Parameter device:       the MTLDevice
  ///
  private func makeBuffers(device: MTLDevice) {
    
    // number of intensity values = width of the frame
    _sizeOfIntensities = WaterfallRenderer.kMaxNumberOfIntensities * MemoryLayout<UInt16>.stride
    
    // overal size of a buffer line = _sizeOfIntensities + one more float for the line number
    _sizeOfLine = _sizeOfIntensities + MemoryLayout<UInt16>.stride
    
    // width * height
    let sizeOfBuffer = _sizeOfLine * WaterfallRenderer.kMaxNumberOfLines
    _intensityBuffer = device.makeBuffer(length: sizeOfBuffer, options: [.storageModeShared])
    
    // number each line
    for i in 0..<WaterfallRenderer.kMaxNumberOfLines {
      var lineNumber = UInt16(i)
      memcpy(_intensityBuffer.contents().advanced(by: (i * _sizeOfLine) + _sizeOfIntensities), &lineNumber, MemoryLayout<UInt16>.stride)
    }
  }
  /// Create the Pipeline
  ///
  /// - Parameter device:       the MTLDevice
  ///
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
  /// Create the Gradient
  ///
  /// - Parameter device:       the MTLDevice
  ///
  private func makeGradient(device: MTLDevice) {
    
    // define a 1D texture for a Gradient
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.textureType = .type1D
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = WaterfallRenderer.kGradientSize
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
  /// Create the Command Queue
  ///
  /// - Parameter device:       the MTLDevice
  ///
  private func makeCommandQueue(device: MTLDevice) {
    
    // create a Command Queue object
    _commandQueue = device.makeCommandQueue()
  }

  
  func setGradient(_ gradient: [UInt8]) {
    
    // copy the Gradient data into the texture
    let region = MTLRegionMake1D(0, WaterfallRenderer.kGradientSize)
    _gradientTexture!.replace(region: region, mipmapLevel: 0, withBytes: gradient, bytesPerRow: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
  }

  
  /// Load a gradient from the named file
  ///
  /// - Parameter name:         a gradient file name
  /// - Returns:                an array of gradient values (if any)
  ///
  private func loadGradient(name: String) -> [UInt8]? {
    var file: FileHandle?
    
    var gradientArray = [UInt8](repeating: 0, count: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
    
    if let texURL = Bundle.main.url(forResource: name, withExtension: "tex") {
      do {
        file = try FileHandle(forReadingFrom: texURL)
      } catch {
        return nil
      }
      // Read all the data
      let data = file!.readDataToEndOfFile()
      
      // Close the file
      file!.closeFile()
      
      // copy the data into the gradientArray
      data.copyBytes(to: &gradientArray[0], count: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
      
      return gradientArray
    }
    // resource not found
    return nil
  }
}

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Change bands & adjust the Waterfall
  ///
//  func bandChange() {
//
//    _parameters[_textureIndex].topLine = 0
//    _binBandwidth = 0
//    _firstBinFreq = 0
//  }
  /// Update the Waterfall
  ///
//  func update() {
//
//    _binBandwidth = 0
//    _firstBinFreq = 0
//  }

// ----------------------------------------------------------------------------
// MARK: - MTKViewDelegate protocol methods

extension WaterfallRenderer                 : MTKViewDelegate {
  
  /// Respond to a change in the size of the MTKView
  ///
  /// - Parameters:
  ///   - view:         the MetalKit View
  ///   - size:         its new size
  ///
  public func mtkView(_ view: MTKView, drawableSizeWillChange newSize: CGSize) {
    
    // capture the new size
    setConstants(size: newSize)
  }
  
  /// Draw a rectangle over the Waterfall area and texture it with the converted Intensities
  ///
  /// - Parameter view:         a MetalKit View
  ///
  public func draw(in view: MTKView) {
    
    // ----- use the GPU to draw lines using the Gradient texture -----
    
    // create a command Buffer
    let buffer = _commandQueue.makeCommandBuffer()!
    
    // create a command Encoder
    let encoder = buffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
    encoder.pushDebugGroup("Draw")
    
    // set the pipeline state
    encoder.setRenderPipelineState(_pipelineState)
    
    // bind the Intensities buffer
    encoder.setVertexBuffer(_intensityBuffer, offset: 0, index: 0)
    encoder.setVertexBuffer(_intensityBuffer, offset: 0, index: 1)
    
    // bind the Constants
    encoder.setVertexBytes(&_constants, length: MemoryLayout<Constants>.size, index: 2)
    
    // bind the Gradient texture
    encoder.setFragmentTexture(_gradientTexture, index: 0)
    
    // bind the Gradient Sampler
    encoder.setFragmentSamplerState(_gradientSamplerState, index: 0)
    
    // Draw the line(s)
    for i in 0..<Int( _constants.numberOfLines) {
      encoder.setVertexBufferOffset(i * _sizeOfLine, index: 0)
      encoder.setVertexBufferOffset((i * _sizeOfLine) + _sizeOfIntensities, index: 1)
      encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: Int(_frameSize.width))
    }
    
    // finish encoding commands
    encoder.endEncoding()
    
    // present the drawable to the screen
    buffer.present(view.currentDrawable!)
    
    // finalize rendering & push the command buffer to the GPU
    buffer.commit()
    buffer.waitUntilCompleted()
    }
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

    // record the current values
    _autoBlackLevel = UInt16(streamFrame.autoBlackLevel)
    _binBandwidth = streamFrame.binBandwidth
    _firstBinFreq = streamFrame.firstBinFreq
    
    // set the Waterfall constants
    // TODO:
    
    assert(streamFrame.totalBins * MemoryLayout<UInt16>.size < _sizeOfLine, "# Bins (\(streamFrame.totalBins * MemoryLayout<UInt16>.size)) > sizeOfLine (_sizeOfLine)")
    
    // copy the Intensities into the current topLine
//    let binsPtr = UnsafeRawPointer(streamFrame.bins).bindMemory(to: UInt8.self, capacity: streamFrame.totalBins * MemoryLayout<UInt16>.size)
//    memcpy(_intensityBuffer.contents().advanced(by: Int(_topLine) * _sizeOfLine), binsPtr, streamFrame.totalBins * MemoryLayout<UInt16>.size)

    addTestLine(line: Int(_topLine))
    
    var bufferValue : UInt16 = 0
    memcpy(&bufferValue, _intensityBuffer.contents().advanced(by: Int(_topLine) * _sizeOfLine) , MemoryLayout<UInt16>.size)
    Swift.print("\(intensityTestData[200]), \(bufferValue)")
    
    // update the Top Line
    if _topLine == 0 {
      _topLine = _constants.numberOfLines - 1
    } else {
      _topLine -= 1
    }
    
    _workerQ.async { [unowned self] in
      autoreleasepool {
        self._metalView.draw()
      }
    }
    
    // update the vertical offset
    if _constants.offsetY == _constants.numberOfLines - 1 {
      _constants.offsetY = 0
    } else {
      _constants.offsetY += 1
    }
  }
  private func makeTestData() {
    
    intensityTestData = [Intensity](repeating: Intensity(i: 0), count: 3360)
    
    let seed : UInt16 = UInt16.max / UInt16(3360)
    for i in 0..<3360 {

//      intensityTestData[i] = Intensity(i: seed * UInt16(i))
      intensityTestData[i] = Intensity(i: UInt16.max / 2)    }
  }

  private func addTestLine(line: Int) {
  
    let binsPtr = UnsafeRawPointer(intensityTestData).bindMemory(to: UInt8.self, capacity: 3360 * MemoryLayout<UInt16>.size)
    memcpy(_intensityBuffer.contents().advanced(by: Int(line) * _sizeOfLine), binsPtr, 3360 * MemoryLayout<UInt16>.size)
  }

}
