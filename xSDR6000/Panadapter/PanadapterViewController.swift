//
//  PanadapterViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/13/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
import os.log
import MetalKit
import SwiftyUserDefaults
import xLib6000

// --------------------------------------------------------------------------------
//  Created by PanafallsViewController
//  Removed by WaterfallViewController
//
//  **** Notifications received ****
//      frameDidChange -> update xPixels & yPixels
//      .panadapterWillBeRemoved -> stop observations, stop stream processing
//      .sliceHasBeenAdd -> add Flag & Slice observations
//      .sliceWillBeRemoved -> remove Flag & slice observations
//      .tnfHasBeenAdded -> add Tnf observations
//      .tnfWillBeRemoved -> remove Tnf observations
//
//  **** Action Methods ****
//      Left Doubleclick -> move active Slice
//      Right Singleclick -> context menu (create/remove Slice/Tnf)
//      ScrollWheel -> Slice frequency +/-
//
//  **** Observations ****
//      Colors:
//        Defaults.dbLegend
//        Defaults.marker
//        Defaults.dbLegendSpacing
//        Defaults.frequencyLegend
//        Defaults.sliceActive
//        Defaults.markerSegment
//        Defaults.markerEdge
//        Defaults.sliceFilter,
//        Defaults.sliceInactive
//        Defaults.tnfActive
//        Defaults.tnfInactive
//        Defaults.gridLine
//        Defaults.spectrum
//        Defaults.spectrumBackground
//
//      Other values:
//        Defaults.spectrumFillLevel
//        Defaults.markersEnabled
//        Panadapter.bandwidth
//        Panadapter.center
//        Radio.tnfsEnabled
//        Tnf.frequency
//        Tnf.depth
//        Tnf.width
//        Tnf.permanent
//
//  **** Constraints manipulated ***
//      None
//
// --------------------------------------------------------------------------------

// --------------------------------------------------------------------------------
// MARK: - Panadapter View Controller class implementation
// --------------------------------------------------------------------------------

final class PanadapterViewController        : NSViewController, NSGestureRecognizerDelegate {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum DragType {
    case dbm                                // +/- Panadapter dbm upper/lower level
    case frequency                          // +/- Panadapter bandwidth
    case slice                              // +/- Slice frequency/width
    case spectrum                           // +/- Panadapter center frequency
    case tnf                                // +/- Tnf frequency/width
  }
  
  struct Dragable {
    var type                                = DragType.spectrum
    var original                            = NSPoint(x: 0.0, y: 0.0)
    var previous                            = NSPoint(x: 0.0, y: 0.0)
    var current                             = NSPoint(x: 0.0, y: 0.0)
    var percent                             : CGFloat = 0.0
    var frequency                           : CGFloat = 0.0
    var cursor                              : NSCursor!
    var object                              : Any?
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _frequencyLegendView : FrequencyLegendView!
  @IBOutlet private weak var _dbLegendView        : DbLegendView!
  @IBOutlet private weak var _panadapterView      : MTKView!

  private var _radio: Radio?                = Api.sharedInstance.radio
  private weak var _panadapter              : Panadapter?
  private var _flags                        = [SliceId:FlagViewController]()
  private var _panadapterRenderer           : PanadapterRenderer!
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "PanadapterVC")

  private var _center                       : Int {return _panadapter!.center }
  private var _bandwidth                    : Int { return _panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  private var _hzPerUnit                    : CGFloat { return CGFloat(_end - _start) / _panadapter!.xPixels }
  
  // gesture recognizer related
  private var _clickLeft                    : NSClickGestureRecognizer!
  private var _clickRight                   : NSClickGestureRecognizer!
  private var _panCenter                    : NSPanGestureRecognizer!
  private var _panBandwidth                 : NSPanGestureRecognizer!
  private var _panRightButton               : NSPanGestureRecognizer!
  private var _panStart                     : NSPoint?
  private var _panSlice                     : xLib6000.Slice?
  private var _panTnf                       : xLib6000.Tnf?
  private var _dbmTop                       = false
  private var _newCursor                    : NSCursor?
  private var _dbLegendSpacings             = [String]()                  // Db spacing choices
  private var _dr                           = Dragable()

  private let kLeftButton                   = 0x01                        // button masks
  private let kRightButton                  = 0x02
  private let kDbLegendWidth                : CGFloat = 40                // width of Db legend
  private let kFrequencyLegendHeight        : CGFloat = 20                // height of the Frequency legend
  private let kFilter                       = CIFilter(name: "CIDifferenceBlendMode")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // determine how the various views are blended on screen
    _panadapterView.compositingFilter = kFilter
    _dbLegendView.compositingFilter = kFilter
    _frequencyLegendView.compositingFilter = kFilter

    // create the Renderer
    _panadapterRenderer = PanadapterRenderer(view: _panadapterView, clearColor: Defaults[.spectrumBackground])

    // tell the Panadapter to tell the Radio the current dimensions
    _panadapter?.xPixels = view.frame.width
    _panadapter?.yPixels = view.frame.height
    
    // update the Constant values with the new size
    _panadapterRenderer.updateConstants(size: view.frame.size)

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
    _frequencyLegendView.configure(panadapter: _panadapter)
    _dbLegendView.configure(panadapter: _panadapter)

    setupObservations()
    
    // make the Renderer the Stream Handler
    _panadapter?.delegate = _panadapterRenderer
    
    
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameter panadapter:               a Panadapter reference
  ///
  func configure(panadapter: Panadapter?) {
    self._panadapter = panadapter
  }
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
      if _dr.original.y < kFrequencyLegendHeight {

        // in frequency legend, bandwidth drag
        _dr.type = .frequency
        _dr.cursor = NSCursor.resizeLeftRight

      } else if _dr.original.x < view.frame.width - kDbLegendWidth {

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
      return view.convert(event.locationInWindow, from: nil).x >= view.frame.width - kDbLegendWidth

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
  // Position Slice flags
  //
  func positionFlags() {
    var current  : (isOnLeft: Bool, freqPosition: CGFloat) = (true, 0.0)
    var previous : (isOnLeft: Bool, freqPosition: CGFloat) = (true, 0.0)

//    Swift.print("_flags = \(_flags)")
    
    // sort the Flags from left to right
    for flagVc in _flags.values.sorted(by: {$0.slice!.frequency < $1.slice!.frequency}) {
      
//      Swift.print("flagVc = \(flagVc)")
      
      // calculate the frequency's position
      current.freqPosition = CGFloat(flagVc.slice!.frequency - _start) / _hzPerUnit
      
      // is there room for the Flag on the left?
      if previous.isOnLeft {
        current.isOnLeft = current.freqPosition - previous.freqPosition > FlagViewController.kFlagWidth + FlagViewController.kFlagOffset
      } else {
        current.isOnLeft = current.freqPosition - previous.freqPosition > 2 * (FlagViewController.kFlagWidth + FlagViewController.kFlagOffset) + 10.0
      }
      
      // Flag position based on room for it
      let flagPosition = (current.isOnLeft ? current.freqPosition - FlagViewController.kFlagWidth - FlagViewController.kFlagOffset : current.freqPosition + FlagViewController.kFlagOffset)
//      Swift.print("flagPosition = \(flagPosition)")
      
      DispatchQueue.main.async { [unowned self] in
        
        if flagVc.flagXPositionConstraint == nil {
          // constraints: leading edge of the Flag (will be changed as Flag moves)
          flagVc.flagXPositionConstraint = flagVc.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: flagPosition)
          flagVc.flagXPositionConstraint!.identifier = "FlagPosition"
          flagVc.flagXPositionConstraint!.isActive = true
          
        } else {
          flagVc.flagXPositionConstraint?.constant = flagPosition
        }
        
//        Swift.print("flagPosition = \(flagPosition)")
//        flagVc.view.needsLayout = true
      }
      // make the current State the previous one
      previous = current
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

    for (_, s) in _radio!.slices {
      
      // only Slices on this Panadapter?
      if thisPanOnly && s.panadapterId != _panadapter!.id {
        
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
    guard let slice = hitTestSlice(at: freq, thisPanOnly: false) else { return false }

    // YES, make the active Slice (if any) inactive
    _radio!.slices.first(where: { $0.value.active} )?.value.active = false

    // make the "hit" Slice active
    slice.active = true

    // return true if slice was found
    return true
  }
  /// Find the Tnf at or near a frequency (if any)
  ///
  /// - Parameter freq:       the target frequency
  /// - Returns:              a tnf or nil
  ///
  private func hitTestTnf(at freq: CGFloat) -> Tnf? {
    var tnf: Tnf? = nil
    
    // calculate a minimum width for hit testing
    let effectiveWidth = Int( CGFloat(_bandwidth) * 0.01)
    
    _radio!.tnfs.forEach {
      let halfWidth = max(effectiveWidth, $0.value.width/2)
      if $0.value.frequency - halfWidth <= Int(freq) && $0.value.frequency + halfWidth >= Int(freq) {
        tnf = $0.value
      }
    }
    return tnf
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods

  private var _baseObservations    = [NSKeyValueObservation]()
  private var _tnfObservations     = [NSKeyValueObservation]()

  /// Add observations of various properties used by the Panadapter
  ///
  private func createBaseObservations(_ observations: inout [NSKeyValueObservation]) {

    observations = [
      Defaults.observe(\.dbLegend, options: [.initial, .new], changeHandler: redrawDbLegend),
      
      Defaults.observe(\.marker, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.dbLegendSpacing, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.frequencyLegend, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.sliceActive, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.markersEnabled, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.markerSegment, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.markerEdge, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.sliceFilter, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.sliceInactive, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.tnfActive, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.tnfInactive, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      Defaults.observe(\.gridLine, options: [.initial, .new], changeHandler: redrawFrequencyAndDbLegend),

      _panadapter!.observe(\.bandwidth, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      _panadapter!.observe(\.center, options: [.initial, .new], changeHandler: redrawFrequencyLegend),
      
      _radio!.observe(\.tnfsEnabled, options: [.initial, .new], changeHandler: redrawFrequencyLegend),

      Defaults.observe(\.spectrumFillLevel, options: [.initial, .new], changeHandler: defaultsObserver),
      Defaults.observe(\.spectrum, options: [.initial, .new], changeHandler: defaultsObserver),
      Defaults.observe(\.spectrumBackground, options: [.initial, .new], changeHandler: defaultsObserver),

    ]
  }
  /// Add observations of Tnf's used by the Panadapter
  ///
  private func addTnfObservations(_ observations: inout [NSKeyValueObservation], tnf: Tnf ) {

    observations.append( tnf.observe(\.frequency, options: [.initial, .new], changeHandler: redrawFrequencyLegend) )
    observations.append( tnf.observe(\.depth, options: [.initial, .new], changeHandler: redrawFrequencyLegend) )
    observations.append( tnf.observe(\.width, options: [.initial, .new], changeHandler: redrawFrequencyLegend) )
    observations.append( tnf.observe(\.permanent, options: [.initial, .new], changeHandler: redrawFrequencyLegend) )
  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(_ observations: inout [NSKeyValueObservation], remove: Bool = true) {

    // invalidate each observation
    observations.forEach { $0.invalidate() }

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

    _panadapterRenderer.updateColor(spectrumColor: Defaults[.spectrum], fillLevel: Defaults[.spectrumFillLevel], fillColor: Defaults[.spectrum])

    // Panadapter background color
    _panadapterView.clearColor = Defaults[.spectrumBackground].metalClearColor
  }
  /// Respond to observations requiring a redraw of the entire Panadapter
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func redrawFrequencyAndDbLegend(_ object: Any, _ change: Any) {
    
    _frequencyLegendView.redraw()
    _dbLegendView.redraw()
  }
  /// Respond to observations requiring a redraw of the FrequencyLegend view
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func redrawFrequencyLegend(_ object: Any, _ change: Any) {
    
    _frequencyLegendView.redraw()
  }
  /// Respond to observations requiring a redraw of the dbLegend view
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func redrawDbLegend(_ object: Any, _ change: Any) {
    
    _dbLegendView.redraw()
  }
//  /// Respond to observations requiring Flags to be moved
//  ///
//  /// - Parameters:
//  ///   - object:                       the object holding the properties
//  ///   - change:                       the change
//  ///
//  private func repositionFlags(_ object: Any, _ change: Any) {
//
//    // call repositionFlag on each FlagVc
//    _flags.forEach( { $0.value.repositionFlag(for: $0.value.slice!)} )
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(frameDidChange(_:)), of: NSView.frameDidChangeNotification.rawValue, object: view)

    NC.makeObserver(self, with: #selector(panadapterWillBeRemoved(_:)), of: .panadapterWillBeRemoved, object: _panadapter!)
    
    NC.makeObserver(self, with: #selector(tnfHasBeenAdded(_:)), of: .tnfHasBeenAdded)
    
    NC.makeObserver(self, with: #selector(tnfWillBeRemoved(_:)), of: .tnfWillBeRemoved)

    NC.makeObserver(self, with: #selector(sliceHasBeenAdded(_:)), of: .sliceHasBeenAdded)
  }
  /// Process frameDidChange Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func frameDidChange(_ note: Notification) {
    

    // tell the Panadapter to tell the Radio the current dimensions
    _panadapter?.xPixels = view.frame.width
    _panadapter?.yPixels = view.frame.height

    // update the Constant values with the new size
    _panadapterRenderer.updateConstants(size: view.frame.size)
  }
  /// Process .panadapterWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func panadapterWillBeRemoved(_ note: Notification) {
    
    // does the Notification contain a Panadapter object?
    let panadapter = note.object as! Panadapter
    
    // stop processing Panadapter streams
    panadapter.delegate = nil
    
    // YES, log the event
    os_log("Panadapter will be removed: ID = %{public}@", log: _log, type: .info, panadapter.id.hex)
    
    // invalidate Base property observations
    invalidateObservations(&_baseObservations)
  }
  /// Process .sliceHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceHasBeenAdded(_ note: Notification) {

    // does the Notification contain a Slice object?
    let slice = note.object as! xLib6000.Slice
    
    // YES, is the slice on this Panadapter?
    if let panadapter = _panadapter, slice.panadapterId == panadapter.id {
      
      // YES, log the event
      os_log("Slice added: ID = %{public}@, pan = %{public}@", log: _log, type: .info, slice.id, panadapter.id.hex)
      
      // observe removal of this Slice
      NC.makeObserver(self, with: #selector(sliceWillBeRemoved(_:)), of: .sliceWillBeRemoved, object: slice)
      
      // add a Flag & Observations of this Slice
      addFlag(for: slice, on: panadapter)
      
      _frequencyLegendView.redraw()
    }
  }
  /// Process .sliceWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceWillBeRemoved(_ note: Notification) {
    
    // does the Notification contain a Slice object?
    let slice = note.object as! xLib6000.Slice
    
    // YES, is the slice on this Panadapter?
    if let panadapter = _panadapter, slice.panadapterId == panadapter.id  {
      
      // YES, log the event
      os_log("Slice will be removed: ID = %{public}@, pan =  %{public}@, freq = %{public}d", log: _log, type: .info, slice.id, panadapter.id.hex, slice.frequency)
      
      // remove the Flag & Observations of this Slice
      removeFlag(for: slice)
      
      // force a redraw
      _frequencyLegendView.redraw()
    }
  }
  /// Process .tnfHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func tnfHasBeenAdded(_ note: Notification) {

    // does the Notification contain a Tnf object?
    let tnf = note.object as! Tnf
    
    // YES, log the event
    os_log("Tnf added: ID = %{public}@", log: _log, type: .info, tnf.id)
    
    // add observations for this Tnf
    addTnfObservations(&_tnfObservations, tnf: tnf)
    
    // force a redraw
    _frequencyLegendView.redraw()
  }
  /// Process .tnfWillBeRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func tnfWillBeRemoved(_ note: Notification) {

    // does the Notification contain a Tnf object?
    let tnfToRemove = note.object as! Tnf
    
    // YES, log the event
    os_log("Tnf will be removed: ID = %{public}@", log: _log, type: .info, tnfToRemove.id)
    
    // invalidate & remove all of the Tnf observations
    invalidateObservations(&_tnfObservations)
    
    // put back all except the one being removed
    _radio!.tnfs.forEach { if $0.value != tnfToRemove { addTnfObservations(&_tnfObservations, tnf: $0.value) } }
    
    // force a redraw
    _frequencyLegendView.redraw()
  }
  /// Create a Flag for the specified Slice
  ///
  /// - Parameter for:            a Slice
  ///
  private func addFlag(for slice: xLib6000.Slice, on pan: Panadapter) {

    DispatchQueue.main.async { [unowned self] in
      
      // get the Storyboard containing a Flag View Controller
      let sb = NSStoryboard(name: "Flag", bundle: nil)
      
      // create a Flag View Controller & pass it needed parameters
      let flagVc = sb.instantiateController(withIdentifier: "Flag") as! FlagViewController
      
      // create a Controls View Controller & pass it needed parameters
      let controlsVc = sb.instantiateController(withIdentifier: "Controls") as! ControlsViewController
      controlsVc.configure(panadapter: pan, slice: slice)
      
      // pass the FlagVc needed parameters
      flagVc.configure(panadapter: pan, slice: slice, controlsVc: controlsVc)
      
      self._flags[slice.id] = flagVc

      self.addChild(flagVc)
      self.addChild(controlsVc)

      // add its view
      self.view.addSubview(flagVc.view)
      self.view.addSubview(controlsVc.view)

      // Flag View constraints: height, width & top of the Flag (constants)
      flagVc.view.heightAnchor.constraint(equalToConstant: FlagViewController.kFlagHeight).isActive = true
      flagVc.view.widthAnchor.constraint(greaterThanOrEqualToConstant: FlagViewController.kFlagWidth).isActive = true
      flagVc.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true

      // Controls View constraints: height, leading, trailing & top of the Controls (constants)
      flagVc.controlsHeightConstraint = controlsVc.view.heightAnchor.constraint(equalToConstant: ControlsViewController.kControlsHeight)
      flagVc.controlsHeightConstraint!.isActive = true
      controlsVc.view.leadingAnchor.constraint(equalTo: flagVc.view.leadingAnchor).isActive = true
      controlsVc.view.trailingAnchor.constraint(equalTo: flagVc.view.trailingAnchor).isActive = true
      controlsVc.view.topAnchor.constraint(equalTo: flagVc.view.bottomAnchor).isActive = true
    }
  }
  /// Remove the Flag on the specified Slice
  ///
  /// - Parameter id:             a Slice Id
  ///
  private func removeFlag(for slice: xLib6000.Slice) {
    
    let flagVc = _flags[slice.id]
    flagVc?.invalidateObservations()

    _flags[slice.id] = nil
    
    DispatchQueue.main.async {
      
      // remove its view
      flagVc?.view.removeFromSuperview()
      
      // remove the view controller
      flagVc?.removeFromParent()

    }
  }
}
