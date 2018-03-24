//
//  WaterfallViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 6/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import MetalKit
import SwiftyUserDefaults
import xLib6000

class WaterfallViewController               : NSViewController, NSGestureRecognizerDelegate {
  
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
  
  var radio: Radio?                         = Api.sharedInstance.radio
  weak var panadapter                       : Panadapter?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _waterfallView : MTKView!
  @IBOutlet private weak var _timeView      : NSView!
  
  private var _waterfallRenderer              : WaterfallRenderer!

  private weak var _waterfall               : Waterfall? { return radio!.waterfalls[panadapter!.waterfallId] }
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
    
//    Swift.print("WaterfallViewController - viewDidLoad")
    
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

//  deinit {
//    Swift.print("WaterfallViewController - deinit")
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  // force a redraw of a layer
  
//  public func redrawTimeLegend() {
//    _timeLayer?.redraw()
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
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

    // begin observations (defaults, panadapter & waterfall)
    observations(UserDefaults.standard, paths: _defaultsKeyPaths)
    observations(panadapter!, paths: _panadapterKeyPaths)
    observations(_waterfall!, paths: _waterfallKeyPaths)

    // add notification subscriptions
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation Methods
  
  private let _defaultsKeyPaths = [
    "spectrumBackground"
  ]
  
  private let _panadapterKeyPaths = [
    #keyPath(Panadapter.band)
  ]
  
  private let _waterfallKeyPaths = [
    #keyPath(Waterfall.autoBlackEnabled),
    #keyPath(Waterfall.blackLevel),
    #keyPath(Waterfall.colorGain),
    #keyPath(Waterfall.gradientIndex)
  ]
  
  /// Add / Remove property observations
  ///
  /// - Parameters:
  ///   - object:         the object of the observations
  ///   - paths:          an array of KeyPaths
  ///   - add:            add / remove (defaults to add)
  ///
  private func observations<T: NSObject>(_ object: T, paths: [String], remove: Bool = false) {

    // for each KeyPath Add / Remove observations
    for keyPath in paths {

      if remove { object.removeObserver(self, forKeyPath: keyPath, context: nil) }
      else { object.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil) }
    }
  }
  /// Observe properties
  ///
  /// - Parameters:
  ///   - keyPath:        the registered KeyPath
  ///   - object:         object containing the KeyPath
  ///   - change:         dictionary of values
  ///   - context:        context (if any)
  ///
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

    switch keyPath! {

    // Defaults
    case "spectrumBackground":
      // reset the spectrum background color
      let color = Defaults[.spectrumBackground]
      _waterfallView.clearColor = MTLClearColor(red: Double(color.redComponent),
                                            green: Double(color.greenComponent),
                                            blue: Double(color.blueComponent),
                                            alpha: Double(color.alphaComponent) )
    // Panadapter
    case #keyPath(Panadapter.band):
      // force the Waterfall to restart
      _waterfallRenderer.restart()

    // Waterfall
    case #keyPath(Waterfall.autoBlackEnabled), #keyPath(Waterfall.blackLevel), #keyPath(Waterfall.colorGain):
      // update the levels
      _waterfallRenderer.updateConstants(autoBlack: _waterfall!.autoBlackEnabled, blackLevel: _waterfall!.blackLevel, colorGain: _waterfall!.colorGain)

    case #keyPath(Waterfall.gradientIndex):
      // reload the Gradient
      _waterfallRenderer.setGradient(loadGradient(index: _waterfall!.gradientIndex) )

    default:
      Log.sharedInstance.msg("Invalid observation - \(keyPath!)", level: .error, function: #function, file: #file, line: #line)
    }
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
    if let waterfall = note.object as? Waterfall {

      // YES, log the event
      Log.sharedInstance.msg("ID = \(waterfall.id.hex), watVc = \(self)", level: .debug, function: #function, file: #file, line: #line)

      // stop processing waterfall data
      waterfall.delegate = nil

//      _waterfallView?.delegate = nil

      // remove Defaults property observers
      observations(UserDefaults.standard, paths: _defaultsKeyPaths, remove: true)

      // remove Panadapter property observers
      observations(panadapter!, paths: _panadapterKeyPaths, remove: true)

      // remove Waterfall property observers
      observations(waterfall, paths: _waterfallKeyPaths, remove: true)

      // remove the UI components of the Panafall
      DispatchQueue.main.async { [unowned self] in
        // remove the entire PanafallButtonViewController hierarchy
        let panafallButtonVc = self.parent!.parent!
        panafallButtonVc.removeFromParentViewController()
      }
    }
  }
}

