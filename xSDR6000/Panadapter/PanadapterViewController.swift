//
//  PanadapterViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/13/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
import MetalKit
import SwiftyUserDefaults
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Panadapter View Controller class implementation
// --------------------------------------------------------------------------------

final class PanadapterViewController          : NSViewController, NSGestureRecognizerDelegate {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var radio: Radio?                           = Api.sharedInstance.radio
  weak var panadapter                         : Panadapter?
  
  enum DragType {
    case dbm                                  // +/- Panadapter dbm upper/lower level
    case frequency                            // +/- Panadapter bandwidth
    case slice                                // +/- Slice frequency/width
    case spectrum                             // +/- Panadapter center frequency
    case tnf                                  // +/- Tnf frequency/width
  }
  
  struct Dragable {
    var type                                  = DragType.spectrum
    var original                              = NSPoint(x: 0.0, y: 0.0)
    var previous                              = NSPoint(x: 0.0, y: 0.0)
    var current                               = NSPoint(x: 0.0, y: 0.0)
    var percent                               : CGFloat = 0.0
    var frequency                             : CGFloat = 0.0
    var cursor                                : NSCursor!
    var object                                : Any?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _frequencyLegendView  : FrequencyLegendView!
  @IBOutlet private weak var _dbLegendView    : DbLegendView!
  @IBOutlet private weak var _panadapterView  : MTKView!

  private var _panadapterRenderer             : PanadapterRenderer!

  private var _center                         : Int {return panadapter!.center }
  private var _bandwidth                      : Int { return panadapter!.bandwidth }
  private var _start                          : Int { return _center - (_bandwidth/2) }
  private var _end                            : Int  { return _center + (_bandwidth/2) }
  private var _hzPerUnit                      : CGFloat { return CGFloat(_end - _start) / view.frame.width }
  
  // gesture recognizer related
  private var _clickLeft                      : NSClickGestureRecognizer!
  private var _clickRight                     : NSClickGestureRecognizer!
  private var _panCenter                      : NSPanGestureRecognizer!
  private var _panBandwidth                   : NSPanGestureRecognizer!
  private var _panRightButton                 : NSPanGestureRecognizer!
  private var _panStart                       : NSPoint?
  private var _panSlice                       : xLib6000.Slice?
  private var _panTnf                         : xLib6000.Tnf?
  private var _dbmTop                         = false
  private var _newCursor                      : NSCursor?
  private var _dbLegendSpacings               = [String]()                  // Db spacing choices
  private var _dr                             = Dragable()

  private let kLeftButton                     = 0x01                        // button masks
  private let kRightButton                    = 0x02
  private let kEdgeTolerance                  = 10                          // percent of bandwidth
  private let _dbLegendWidth                  : CGFloat = 40                // width of Db legend
  private let _frequencyLegendHeight          : CGFloat = 20                // height of the Frequency legend
  private let _filter                         = CIFilter(name: "CIDifferenceBlendMode")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    Swift.print("PanadapterViewController - viewDidLoad")
    
    // determine how the various views are blended on screen
    _panadapterView.compositingFilter = _filter
    _dbLegendView.compositingFilter = _filter
    _frequencyLegendView.compositingFilter = _filter

    // create the Renderer
    _panadapterRenderer = PanadapterRenderer(view: _panadapterView, clearColor: Defaults[.spectrumBackground])

    // get the list of possible Db level spacings
    _dbLegendSpacings = Defaults[.dbLegendSpacings]
    
    // Click, LEFT in panadapter
    _clickLeft = NSClickGestureRecognizer(target: self, action: #selector(clickLeft(_:)))
    _clickLeft.buttonMask = kLeftButton
    _clickLeft.delegate = self
    _panadapterView.addGestureRecognizer(_clickLeft)

    // Click, RIGHT in panadapter
    _clickRight = NSClickGestureRecognizer(target: self, action: #selector(clickRight(_:)))
    _clickRight.buttonMask = kRightButton
    _clickRight.delegate = self
    _dbLegendView.addGestureRecognizer(_clickRight)

    // Pan, LEFT in panadapter
    _panCenter = NSPanGestureRecognizer(target: self, action: #selector(panLeft(_:)))
    _panCenter.buttonMask = kLeftButton
    _panCenter.delegate = self
    _dbLegendView.addGestureRecognizer(_panCenter)

    // Pan, LEFT in Frequency legend
    _panBandwidth = NSPanGestureRecognizer(target: self, action: #selector(panLeft(_:)))
    _panBandwidth.buttonMask = kLeftButton
    _panBandwidth.delegate = self
    _frequencyLegendView.addGestureRecognizer(_panBandwidth)

    // pass a reference to the Panadapter
    _frequencyLegendView.panadapter = panadapter
    _dbLegendView.panadapter = panadapter

    setupObservations()
    
    // make the Renderer the Stream Handler
    panadapter?.delegate = _panadapterRenderer
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods

  /// start observations & Notification
  ///
  private func setupObservations() {

    // add notification subscriptions
    addNotifications()

    // begin observations (defaults, panadapter & radio)
    createBaseObservations(&_baseObservations)
  }
  
  // force a redraw of a view
  
  func redrawFrequencyLegend() {
    _frequencyLegendView.redraw()
  }
  func redrawDbLegend() {
    _dbLegendView.redraw()
  }
  func redrawTnfs() {
    _frequencyLegendView.redraw()
  }
  func redrawSlices() {
    _frequencyLegendView.redraw()
  }
  /// Respond to Pan gesture (left mouse down)
  ///
  /// - Parameter gr:         the Pan Gesture Recognizer
  ///
  @objc func panLeft(_ gr: NSPanGestureRecognizer) {

    // ----------------------------------------------------------------------------
    // nested function to update layers
    func update(_ dr: Dragable) {

      // call the appropriate function on the appropriate layer
      switch dr.type {
      case .dbm:
        _dbLegendView.updateDbmLevel(dragable: dr)

      case .frequency:
        _frequencyLegendView.updateBandwidth(dragable: dr)

      case .slice:
        _frequencyLegendView.updateSlice(dragable: dr)

      case .spectrum:
        _frequencyLegendView.updateCenter(dragable: dr)

      case .tnf:
        _frequencyLegendView.updateTnf(dragable: dr)        
      }
    }
    // ----------------------------------------------------------------------------

    // get the current position
    _dr.current = gr.location(in: view)

    // save the starting position
    if gr.state == .began {
      _dr.original = _dr.current

      // calculate start's percent of width & it's frequency
      _dr.percent = _dr.current.x / view.frame.width
      _dr.frequency = (_dr.percent * CGFloat(_bandwidth)) + CGFloat(_start)

      _dr.object = nil

      // what type of drag?
      if _dr.original.y < _frequencyLegendHeight {

        // in frequency legend, bandwidth drag
        _dr.type = .frequency
        _dr.cursor = NSCursor.resizeLeftRight

      } else if _dr.original.x < view.frame.width - _dbLegendWidth {

        // in spectrum, check for presence of Slice or Tnf
        let dragSlice = hitTestSlice(at: _dr.frequency)
        let dragTnf = hitTestTnf(at: _dr.frequency)
        if let _ =  dragSlice{
          // in Slice drag / resize
          _dr.type = .slice
          _dr.object = dragSlice
          _dr.cursor = NSCursor.crosshair

        } else if let _ = dragTnf {
          // in Tnf drag / resize
          _dr.type = .tnf
          _dr.object = dragTnf
          _dr.cursor = NSCursor.crosshair

        } else {
          // spectrum drag
          _dr.type = .spectrum
          _dr.cursor = NSCursor.resizeLeftRight
        }
      } else {
        // in db legend, db legend drag
        _dr.type = .dbm
        _dr.cursor = NSCursor.resizeUpDown
      }
    }
    // what portion of the drag are we in?
    switch gr.state {

    case .began:
      // set the cursor
      _dr.cursor.push()

      // save the starting coordinate
      _dr.previous = _dr.current

    case .changed:
      // update the appropriate layer
      update(_dr)

      // save the current (intermediate) location as the previous
      _dr.previous = _dr.current

    case .ended:
      // update the appropriate layer
      update(_dr)

      // restore the previous cursor
      NSCursor.pop()

    default:
      // ignore other states
      break
    }
  }
  /// Prevent the Right Click recognizer from responding when the mouse is not over the Legend
  ///
  /// - Parameters:
  ///   - gr:           the Gesture Recognizer
  ///   - event:        the Event
  /// - Returns:        True = allow, false = ignore
  ///
  func gestureRecognizer(_ gr: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {

    // is it a right click?
    if gr.action == #selector(PanadapterViewController.clickRight(_:)) {

      // YES, if not over the legend, push it up the responder chain
      return view.convert(event.locationInWindow, from: nil).x >= view.frame.width - _dbLegendWidth

    } else {

      // NO, process it
      return true
    }
  }
  /// Respond to Right-Click gesture
  ///     NOTE: will only receive events in db legend (see gestureRecognizer method above)
  ///
  /// - Parameter gr:         the Click Gesture Recognizer
  ///
  @objc func clickRight(_ gr: NSClickGestureRecognizer) {

    // update the Db Legend spacings
    _dbLegendView.updateLegendSpacing(gestureRecognizer: gr, in: view)
  }
  /// Respond to Click-Left gesture
  ///
  /// - Parameter gr:         the Click Gesture Recognizer
  ///
  @objc func clickLeft(_ gr: NSClickGestureRecognizer) {

    // get the coordinates and convert to this View
    let mouseLocation = gr.location(in: view)

    // calculate the frequency
    let clickFrequency = (mouseLocation.x * _hzPerUnit) + CGFloat(_start)

    // activate the Slice at the clickFrequency (if any)
    if activateSlice(at: clickFrequency) {

      // redraw if a Slice was activated
      redrawSlices()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Find the Slice at a frequency (if any)
  ///
  /// - Parameter freq:       the target frequency
  /// - Returns:              a slice or nil
  ///
  private func hitTestSlice(at freq: CGFloat, thisPanOnly: Bool = true) -> xLib6000.Slice? {
    var slice: xLib6000.Slice?
    
    for (_, s) in radio!.slices {
      
      // only Slices on this Panadapter?
      if thisPanOnly && s.panadapterId != panadapter!.id {
        
        // YES, skip this Slice
        continue
      }
      // is the Slice within the Panadapter bandwidth?
      if s.frequency + s.filterLow <= Int(freq) && s.frequency + s.filterHigh >= Int(freq) {
        
        // YES, save it and break out
        slice = s
        break
      }
    }
    return slice
  }
  /// Make a Slice active
  ///
  /// - Parameter freq:       the target frequency
  ///
  private func activateSlice(at freq: CGFloat) -> Bool {
    
    // is there a Slice at the indicated freq?
    let slice = hitTestSlice(at: freq, thisPanOnly: false)
    if let slice = slice {
      
      // YES, make the active Slice inactive
      for (_, s) in radio!.slices where s.active {
        
        s.active = false
      }
      // make the "hit" slice active
      slice.active = true
      
    }
    // return true if slice was found
    return slice != nil
  }
  /// Find the Tnf at or near a frequency (if any)
  ///
  /// - Parameter freq:       the target frequency
  /// - Returns:              a tnf or nil
  ///
  private func hitTestTnf(at freq: CGFloat) -> Tnf? {
    var tnf: Tnf?
    
    // calculate a minimum width for hit testing
    let effectiveWidth = Int( CGFloat(_bandwidth) * 0.01)
    
    for (_, t) in radio!.tnfs {
      
      let halfWidth = max(effectiveWidth, t.width/2)
      if t.frequency - halfWidth <= Int(freq) && t.frequency + halfWidth >= Int(freq) {
        tnf = t
        break
      }
    }
    return tnf
  }

  // ----------------------------------------------------------------------------
  // MARK: - NEW Observation methods

  private var _baseObservations    = [NSKeyValueObservation]()
  private var _tnfObservations     = [NSKeyValueObservation]()

  /// Add observations of various properties
  ///
  private func createBaseObservations(_ observations: inout [NSKeyValueObservation]) {

    observations = [
      Defaults.observe(\.bandMarker, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.dbLegend, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.dbLegendSpacing, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.frequencyLegend, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.gridLines, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.gridLinesDashed, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.gridLineWidth, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.sliceActive, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.showMarkers, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.sliceFilter, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.sliceInactive, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.tnfActive, options: [.initial, .new], changeHandler: redrawObserver),
      Defaults.observe(\.tnfInactive, options: [.initial, .new], changeHandler: redrawObserver),

      Defaults.observe(\.fillLevel, options: [.initial, .new], changeHandler: defaultsObserver),
      Defaults.observe(\.spectrum, options: [.initial, .new], changeHandler: defaultsObserver),
      Defaults.observe(\.spectrumBackground, options: [.initial, .new], changeHandler: defaultsObserver),

      panadapter!.observe(\.bandwidth, options: [.initial, .new], changeHandler: redrawObserver),
      panadapter!.observe(\.center, options: [.initial, .new], changeHandler: redrawObserver),
      
      radio!.observe(\.tnfEnabled, options: [.initial, .new], changeHandler: redrawObserver),
    ]
  }
  /// Add observers for Slice properties
  ///
    private func createSliceObservations(_ observations: inout [NSKeyValueObservation], object: xLib6000.Slice ) {

      observations = [
        object.observe(\xLib6000.Slice.active, options: [.initial, .new], changeHandler: redrawObserver),
        object.observe(\xLib6000.Slice.filterHigh, options: [.initial, .new], changeHandler: redrawObserver),
        object.observe(\xLib6000.Slice.filterLow, options: [.initial, .new], changeHandler: redrawObserver),
        object.observe(\xLib6000.Slice.frequency, options: [.initial, .new], changeHandler: redrawObserver)
      ]
  }
  /// Add observers for Tnf properties
  ///
  private func addTnfObservations(_ observations: inout [NSKeyValueObservation], object: Tnf ) {

    observations.append( object.observe(\.depth, options: [.initial, .new], changeHandler: redrawObserver) )
    observations.append( object.observe(\.depth, options: [.initial, .new], changeHandler: redrawObserver) )
    observations.append( object.observe(\.frequency, options: [.initial, .new], changeHandler: redrawObserver) )
    observations.append( object.observe(\.width, options: [.initial, .new], changeHandler: redrawObserver) )
    observations.append( object.observe(\.permanent, options: [.initial, .new], changeHandler: redrawObserver) )
  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(_ observations: inout [NSKeyValueObservation], remove: Bool = true) {

    // invalidate each observation
    for observation in observations {
      observation.invalidate()
    }
    // if specified, remove the tokens
    if remove { observations.removeAll() }
  }
  /// Respond to Defaults observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func defaultsObserver(_ object: UserDefaults, _ change: Any) {

    _panadapterRenderer.updateColor(spectrumColor: Defaults[.spectrum], fillLevel: Defaults[.fillLevel], fillColor: Defaults[.spectrum])

    // Panadapter background color
    let color = Defaults[.spectrumBackground]
    _panadapterView.clearColor = MTLClearColor(red: Double(color.redComponent),
                                               green: Double(color.greenComponent),
                                               blue: Double(color.blueComponent),
                                               alpha: Double(color.alphaComponent) )
  }
  /// Respond to observations requiring a redraw
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func redrawObserver(_ object: Any, _ change: Any) {
    
    _frequencyLegendView.redraw()
    _dbLegendView.redraw()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(frameDidChange(_:)), of: NSView.frameDidChangeNotification.rawValue, object: view)

    NC.makeObserver(self, with: #selector(panadapterWillBeRemoved(_:)), of: .panadapterWillBeRemoved, object: panadapter!)
    
    NC.makeObserver(self, with: #selector(tnfHasBeenAdded(_:)), of: .tnfHasBeenAdded, object: nil)
    
    NC.makeObserver(self, with: #selector(tnfWillBeRemoved(_:)), of: .tnfWillBeRemoved, object: nil)

    NC.makeObserver(self, with: #selector(sliceHasBeenAdded(_:)), of: .sliceHasBeenAdded, object: nil)
  }
  /// Process frameDidChange Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func frameDidChange(_ note: Notification) {
    
    // tell the Panadapter to tell the Radio the current dimensions
    panadapter?.xPixels = view.frame.width
    panadapter?.yPixels = view.frame.height
    
    // update the Constant values with the new size
    _panadapterRenderer.updateConstants(size: view.frame.size)
  }
  /// Process .panadapterWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func panadapterWillBeRemoved(_ note: Notification) {
    
    // does the Notification contain a Panadapter object?
    if let panadapter = note.object as? Panadapter {
      
      // stop processing Panadapter streams
      panadapter.delegate = nil
      
      // YES, log the event
      Log.sharedInstance.msg("ID = \(panadapter.id.hex)", level: .debug, function: #function, file: #file, line: #line)
      
//      for flag in _frequencyLegendView.flags {
//
//        // remove the Slice Flag & property observations
//        removeFlag(for: flag.slice!)
//      }

      // invalidate Base property observations
      invalidateObservations(&_baseObservations)
    }
  }
  /// Process .sliceHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceHasBeenAdded(_ note: Notification) {

    // does the Notification contain a Slice object?
    if let slice = note.object as? xLib6000.Slice {
      
      // YES, is the slice on this Panadapter?
      if let panadapter = panadapter, slice.panadapterId == panadapter.id {
        
        // YES, log the event
        Log.sharedInstance.msg("ID = \(slice.id), pan = \(panadapter.id.hex)", level: .debug, function: #function, file: #file, line: #line)
        
        // observe removal of this Slice
        NC.makeObserver(self, with: #selector(sliceWillBeRemoved(_:)), of: .sliceWillBeRemoved, object: slice)
        
        // add a Flag & Observations of this Slice
        addFlag(for: slice)
        
        // force a redraw
        _frequencyLegendView.redraw()
      }
    }
  }
  /// Process .sliceWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceWillBeRemoved(_ note: Notification) {
    
    // does the Notification contain a Slice object?
    if let slice = note.object as? xLib6000.Slice {
      
      // YES, is the slice on this Panadapter?
      if let panadapter = panadapter, slice.panadapterId == panadapter.id  {
        
        // YES, log the event
        Log.sharedInstance.msg("ID = \(slice.id), pan = \(panadapter.id.hex)", level: .debug, function: #function, file: #file, line: #line)
        
        // remove the Flag & Observations of this Slice
        removeFlag(for: slice)
        
        // force a redraw
        _frequencyLegendView.redraw()
      }
    }
  }
  /// Process .tnfHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func tnfHasBeenAdded(_ note: Notification) {

    // does the Notification contain a Tnf object?
    if let tnf = note.object as? Tnf {

      // YES, log the event
      Log.sharedInstance.msg("ID = \(tnf.id)", level: .debug, function: #function, file: #file, line: #line)

      // add observations for this Tnf
      addTnfObservations(&_tnfObservations, object: tnf)
      
      // force a redraw
      _frequencyLegendView.redraw()
    }
  }
  /// Process .tnfWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func tnfWillBeRemoved(_ note: Notification) {

    // does the Notification contain a Tnf object?
    if let tnfToRemove = note.object as? Tnf {

      // YES, log the event
      Log.sharedInstance.msg("ID = \(tnfToRemove.id)", level: .debug, function: #function, file: #file, line: #line)

      // invalidate & remove all of the Tnf observations
      invalidateObservations(&_tnfObservations)
      
      // put back all except the one being removed
      for (_, tnf) in radio!.tnfs {
        if tnf != tnfToRemove { addTnfObservations(&_tnfObservations, object: tnf) }
      }

      // force a redraw
      _frequencyLegendView.redraw()
    }
  }
  /// Create a Flag for the specified Slice
  ///
  /// - Parameter for:            a Slice
  ///
  private func addFlag(for slice: xLib6000.Slice) {

    Log.sharedInstance.msg("Slice \(slice.id)", level: .debug, function: #function, file: #file, line: #line)
    
    // get the Storyboard containing a Flag View Controller
    let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: "Flag"), bundle: nil)

    // create a Flag View Controller
    let flagVc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Flag")) as! FlagViewController

    // set its Slice
    flagVc.panadapter = panadapter
    flagVc.slice = slice
    
    // create the Slice observations
    createSliceObservations( &flagVc.sliceObservations, object: flagVc.slice!)

    _frequencyLegendView.flags.append(flagVc)

    addChildViewController(flagVc)

    DispatchQueue.main.sync { [unowned self] in
      
      // add its view
      self.view.addSubview(flagVc.view)
      
      // force a redraw
      self._frequencyLegendView.redraw()
    }
  }
  /// Remove the Flag on the specified Slice
  ///
  /// - Parameter id:             a Slice Id
  ///
  private func removeFlag(for slice: xLib6000.Slice) {
    var indexToRemove : Int?

    for (i, flagVc) in _frequencyLegendView.flags.enumerated() where flagVc.slice == slice {

      Log.sharedInstance.msg("Slice \(flagVc.slice!.id)", level: .debug, function: #function, file: #file, line: #line)
      
      // remove the Slice observers
      invalidateObservations(&flagVc.sliceObservations)
      
      indexToRemove = i

      DispatchQueue.main.async {

        // remove its view
        flagVc.view.removeFromSuperview()

        // remove the view controller
        flagVc.removeFromParentViewController()
      }
    }
    // remove the Flags entry if the Slice was found
    if let indexToRemove = indexToRemove { _frequencyLegendView.flags.remove(at: indexToRemove) }
  }
}
