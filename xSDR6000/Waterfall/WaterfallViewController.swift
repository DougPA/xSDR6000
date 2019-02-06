//
//  WaterfallViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 6/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import os.log
import MetalKit
import SwiftyUserDefaults
import xLib6000

final class WaterfallViewController               : NSViewController, NSGestureRecognizerDelegate {
  
  enum GradientType: String {
    case Basic
    case Dark
    case Deuteranopia
    case Grayscale
    case Purple
    case Tritanopia
  }
  static let gradientNames = [
    GradientType.Basic.rawValue,
    GradientType.Dark.rawValue,
    GradientType.Deuteranopia.rawValue,
    GradientType.Grayscale.rawValue,
    GradientType.Purple.rawValue,
    GradientType.Tritanopia.rawValue
  ]
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @objc dynamic weak var panadapter         : Panadapter?

  var radio: Radio?                         = Api.sharedInstance.radio
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _waterfallView : MTKView!
  @IBOutlet private weak var _timeView      : NSView!
  
  private var _waterfallRenderer            : WaterfallRenderer!

  private weak var _waterfall               : Waterfall? { return radio!.waterfalls[panadapter!.waterfallId] }
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "WaterfallVC")
  private var _center                       : Int { return panadapter!.center }
  private var _bandwidth                    : Int { return panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  private var _hzPerUnit                    : CGFloat { return CGFloat(_end - _start) / panadapter!.xPixels }
  
  // constants
  private let _filter                       = CIFilter(name: "CIDifferenceBlendMode")

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  


  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// The View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // determine how the various views are blended on screen
    _waterfallView.compositingFilter = _filter

    // create the Renderer
    _waterfallRenderer = WaterfallRenderer(view: _waterfallView, clearColor: Defaults[.spectrumBackground])
    
    _waterfallRenderer.panadapter = panadapter

    // setup the gradient texture
    _waterfallRenderer.setGradient( loadGradient(index: _waterfall!.gradientIndex) )
    
    setupObservations()

    // make the Renderer the Stream Handler
    _waterfall?.delegate = _waterfallRenderer
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  // force a redraw of a layer
  
//  public func redrawTimeLegend() {
//    _timeLayer?.redraw()
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameter panadapter:               a Panadapter reference
  ///
  func configure(panadapter: Panadapter?) {
    self.panadapter = panadapter
  }
  /// Load the gradient at the specified index
  ///
  func loadGradient(index: Int) -> [UInt8] {
    var i = 0
    if (0..<WaterfallViewController.gradientNames.count).contains(index) { i = index }
    
    return loadGradient(name: WaterfallViewController.gradientNames[i])
  }
  /// Load the gradient from the named file
  ///
  func loadGradient(name: String) -> [UInt8] {
    var file: FileHandle?
    
    var gradientArray = [UInt8](repeating: 0, count: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
    
    if let texURL = Bundle.main.url(forResource: name, withExtension: "tex") {
      do {
        file = try FileHandle(forReadingFrom: texURL)
      } catch {
        fatalError("Unable to read Gradient file -> \(name).tex")
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
    fatalError("Unable to find Gradient file -> \(name).tex")
  }
//  /// Prevent the Right Click recognizer from responding when the mouse is not over the Legend
//  ///
//  /// - Parameters:
//  ///   - gr:             the Gesture Recognizer
//  ///   - event:          the Event
//  /// - Returns:          True = allow, false = ignore
//  ///
//  func gestureRecognizer(_ gr: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
//
//    // is it a right click?
//    if gr.action == #selector(WaterfallViewController.clickRight(_:)) {
//      // YES, if not over the legend, push it up the responder chain
//      return view.convert(event.locationInWindow, from: nil).x >= view.frame.width - _waterfallView!.timeLegendWidth
//    } else {
//      // not right click, process it
//      return true
//    }
//  }
//  /// respond to Right Click gesture
//  ///     NOTE: will only receive events in time legend, see previous method
//  ///
//  /// - Parameter gr:     the Click Gesture Recognizer
//  ///
//  @objc func clickRight(_ gr: NSClickGestureRecognizer) {
//
//    // update the time Legend
//    _timeLayer?.updateLegendSpacing(gestureRecognizer: gr, in: view)
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// start observations & Notification
  ///
  private func setupObservations() {

    // begin observations (panadapter, waterfall & Defaults)
    createBaseObservations(&_baseObservations)
    
    // add notification subscriptions
    addNotifications()
  }

  // ----------------------------------------------------------------------------
  // MARK: - NEW Observation methods

  private var _baseObservations        = [NSKeyValueObservation]()
  
  /// Add observations of various properties
  ///
  private func createBaseObservations(_ observations: inout [NSKeyValueObservation]) {
    
    observations = [
      panadapter!.observe(\.band, options: [.initial, .new], changeHandler: panadapterBandchange),
      panadapter!.observe(\.bandwidth, options: [.initial, .new], changeHandler: panadapterUpdate),
      panadapter!.observe(\.center, options: [.initial, .new], changeHandler: panadapterUpdate),
      _waterfall!.observe(\.autoBlackEnabled, options: [.initial, .new], changeHandler: waterfallObserverLevels),
      _waterfall!.observe(\.blackLevel, options: [.initial, .new], changeHandler: waterfallObserverLevels),
      _waterfall!.observe(\.colorGain, options: [.initial, .new], changeHandler: waterfallObserverLevels),
      _waterfall!.observe(\.gradientIndex, options: [.initial, .new], changeHandler: waterfallObserverGradient),

      Defaults.observe(\.spectrumBackground, options: [.initial, .new], changeHandler: defaultsObserver)
    ]
  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(_ observations: inout [NSKeyValueObservation], remove: Bool = true) {
    
    // invalidate each observation
    observations.forEach {$0.invalidate()} 

    // if specified, remove the tokens
    if remove { observations.removeAll() }
  }
  /// Respond to Panadapter observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func panadapterUpdate(_ object: Panadapter, _ change: Any) {

      // update the Waterfall
      _waterfallRenderer.update()
  }
  /// Respond to Panadapter observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func panadapterBandchange(_ object: Panadapter, _ change: Any) {
    
    // force the Waterfall to restart
    _waterfallRenderer.bandChange()
  }
  /// Respond to Waterfall observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func waterfallObserverLevels(_ waterfall: Waterfall, _ change: Any) {

      // update the levels
      _waterfallRenderer.updateConstants(autoBlack: waterfall.autoBlackEnabled, blackLevel: waterfall.blackLevel, colorGain: waterfall.colorGain)
    }
  /// Respond to Waterfall observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func waterfallObserverGradient(_ waterfall: Waterfall, _ change: Any) {

      // reload the Gradient
      _waterfallRenderer.setGradient(loadGradient(index: waterfall.gradientIndex) )
  }
  /// Respond to Defaults observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func defaultsObserver(_ defaults: UserDefaults, _ change: Any) {

      // reset the spectrum background color
      let color = defaults[.spectrumBackground]
      _waterfallView.clearColor = MTLClearColor(red: Double(color.redComponent),
                                                     green: Double(color.greenComponent),
                                                     blue: Double(color.blueComponent),
                                                     alpha: Double(color.alphaComponent) )
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {

    // only receive removal Notifications sent by this Waterfall
    NC.makeObserver(self, with: #selector(waterfallWillBeRemoved(_:)), of: .waterfallWillBeRemoved, object: _waterfall!)
  }
  /// Process .waterfallWillBeRemoved Notification
  ///
  /// - Parameter note:         a Notification instance
  ///
  @objc private func waterfallWillBeRemoved(_ note: Notification) {

    // does the Notification contain a Panadapter object?
    let waterfall = note.object as! Waterfall
    
    // YES, log the event
    os_log("Waterfall will be removed, ID = %{public}@", log: _log, type: .info, waterfall.id.hex)
    
    // stop processing waterfall data
    waterfall.delegate = nil
    
    // invalidate all property observers
    invalidateObservations(&_baseObservations)
    
    // remove the UI components of the Panafall
    DispatchQueue.main.async { [unowned self] in
    
      // remove the entire PanafallButtonViewController hierarchy
      let panafallButtonVc = self.parent!.parent!
      panafallButtonVc.removeFromParent()
    }
  }
}

