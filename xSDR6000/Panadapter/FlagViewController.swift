//
//  FlagViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/22/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Flag View Controller class implementation
// --------------------------------------------------------------------------------

final public class FlagViewController       : NSViewController {
  
  static let kSliceLetters : [String]       = ["A", "B", "C", "D", "E", "F", "G", "H"]
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @objc dynamic weak var slice              : xLib6000.Slice?

  var onLeft                                = true
  var sliceObservations                     = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
    
  @IBOutlet private weak var _alpha         : NSTextField!
  @IBOutlet private weak var _sMeter        : NSLevelIndicator!
  @IBOutlet private weak var _filter        : NSTextField!
  
  @IBOutlet weak var _containerView         : NSView!
  @IBOutlet weak var _containerViewHeight   : NSLayoutConstraint!
  
  private var _tabViewController            : NSTabViewController?
  private var _previousTabIndex             : Int?

  private var _storyBoard                   : NSStoryboard?
  private var _viewController               : NSViewController?

  private var _position                     = NSPoint(x: 0.0, y: 0.0)
  
  private let kFlagOffset                   : CGFloat = 15.0/2.0
  private let kTabViewOpen                  : CGFloat = 93.0
  private let kTabViewClosed                : CGFloat = 0.0
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // get the storyboard
    _storyBoard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Flag"), bundle: nil)
    
    // close the display area
    _containerViewHeight.constant = 0 

    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // set the Alpha ID
    _alpha.stringValue = FlagViewController.kSliceLetters[Int(slice!.id)!]

    // begin slice observations
    createObservations(&_observations, object: slice!)
    
    // start receiving Notifications
    addNotifications()
    
    // find the S-Meter feed (if any)
    sMeter()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// One of the "tab" view buttons has been clicked
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    // display / hide the selected view
    selectView(sender.identifier!.rawValue)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Move a Slice Flag to the specified position
  ///
  /// - Parameters:
  ///   - frequencyPosition: the desired position
  ///   - onLeft: Flag placement (Left / Right of frequency)
  ///
  func moveTo(_ frequencyPosition: NSPoint, onLeft: Bool) {
    
    self.onLeft = onLeft
    
    // What side should the Flag be on?
    if onLeft {
      
      // LEFT
      _position.x = frequencyPosition.x - view.frame.width - kFlagOffset
      
    } else {
      
      // RIGHT
      _position.x = frequencyPosition.x + kFlagOffset
    }
    _position.y = frequencyPosition.y
    
    // update the flag's position
    view.setFrameOrigin(_position)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Select a view to display
  ///
  /// - Parameter id:             the ID of the selected view
  ///
  private func selectView(_ id: String) {
    var flagAdjustMinus = true
    
    // _viewController is the last one displayed, id is AUD, DSP, MODE, XRIT or DAX
    switch (_viewController, id + "vc") {
      
    case (nil, _):                                          // NO PREVIOUS TAB
      
      // get the selected tab
      _viewController = _storyBoard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: id)) as? NSViewController
      
      _viewController!.representedObject = slice! as Any

      // open the display area with the appropriate height
      _containerViewHeight.constant = _viewController!.view.frame.size.height
      
      // add the view
      _containerView.addSubview(_viewController!.view)
      
    case (_, _viewController!.identifier!.rawValue):        // SAME TAB AS PREVIOUS
      
      if _containerViewHeight.constant == kTabViewClosed {
        
        // is closed, open the display area with the appropriate height
        _containerViewHeight.constant = _viewController!.view.frame.size.height
        
      } else {
        
        // is open, close the display area
        _containerViewHeight.constant = kTabViewClosed
        
        flagAdjustMinus = false
      }
      
    default:                                                // DIFFERENT TAB FROM PREVIOUS
      
      // remove the current tab
      _viewController!.view.removeFromSuperview()
      
      // if open, adjust the flag position
      if _containerViewHeight.constant != kTabViewClosed { view.frame.origin.y = view.frame.origin.y + _viewController!.view.frame.size.height }
      
      // get the selected tab
      _viewController = _storyBoard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: id)) as? NSViewController
      _viewController!.representedObject = slice! as Any

      // open the display area with the appropriate height
      _containerViewHeight.constant = _viewController!.view.frame.size.height
      
      // add the tab
      _containerView.addSubview(_viewController!.view)
    }
    
    // adjust the flag position
    let tabHeight = _viewController!.view.frame.size.height
    view.frame.origin.y = view.frame.origin.y + (flagAdjustMinus ? -tabHeight : tabHeight)
  }

  // ----------------------------------------------------------------------------
  // MARK: - NEW Observation methods
  
  private var _observations    = [NSKeyValueObservation]()
  
  /// Add observers for Slice properties
  ///
  private func createObservations(_ observations: inout [NSKeyValueObservation], object: xLib6000.Slice ) {

    observations = [
//      object.observe(\.txEnabled, options: [.new], changeHandler: observer),
//      object.observe(\.nbEnabled, options: [.initial, .new], changeHandler: observer),
//      object.observe(\.nrEnabled, options: [.new], changeHandler: observer),
//      object.observe(\.anfEnabled, options: [.new], changeHandler: observer),
//      object.observe(\.qskEnabled, options: [.new], changeHandler: observer),
      object.observe(\.filterHigh, options: [.new], changeHandler: observer),
      object.observe(\.filterLow, options: [.new], changeHandler: observer),
//      object.observe(\.locked, options: [.new], changeHandler: observer)
    ]
  }
  private func observer(_ object: Any, _ change: Any) {

    let width = Float(slice!.filterHigh - slice!.filterLow)/1000.0

    DispatchQueue.main.async { [unowned self] in
//      self._txButton.state = self.slice!.txEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
//      self._nbButton.state = self.slice!.nbEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
//      self._nrButton.state = self.slice!.nrEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
//      self._anfButton.state = self.slice!.anfEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
//      self._qskButton.state = self.slice!.qskEnabled ? NSControl.StateValue.on : NSControl.StateValue.off

      self._filter.stringValue = String(format: "%3.1fk", width)
//
//      self._lock.state = (self.slice!.locked ? NSControl.StateValue.on : NSControl.StateValue.off)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {

    NC.makeObserver(self, with: #selector(sliceMeterHasBeenAdded(_:)), of: .sliceMeterHasBeenAdded, object: nil)
  }
  private var _levelObservation    : NSKeyValueObservation?
  
  /// Process sliceMeterHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceMeterHasBeenAdded(_ note: Notification) {

    // does the Notification contain a Meter object for this Slice?
    if let meter = note.object as? Meter, meter.number == slice!.id {
      sMeter()
    }
  }
  /// Find the S-Meter feed
  ///
  ///     Note: meters may not be available at Slice creation.
  ///     If not, the .sliceMeterHasBeenAdded notification will identify the S-Meter
  ///
  func sMeter() {
    
    // get the S-Meter for this slice
    for (_, meter) in slice!.meters where meter.name == Api.MeterShortName.signalPassband.rawValue {
      
      // S-Meter
      _levelObservation = meter.observe(\.value, options: [.initial, .new]) { (meter, change) in
        
        // process observations of the S-Meter
        DispatchQueue.main.async { [unowned self] in
          self._sMeter.floatValue = meter.value
        }
      }
    }
  }
}
