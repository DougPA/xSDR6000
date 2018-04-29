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

@objcMembers final public class FlagViewController       : NSViewController {
  
  static let kSliceLetters : [String]       = ["A", "B", "C", "D", "E", "F", "G", "H"]
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  dynamic weak var slice                    : xLib6000.Slice?
  var onLeft                                = true
  var sliceObservations                     = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _nbButton     : NSButton!
  @IBOutlet private weak var _nrButton     : NSButton!
  @IBOutlet private weak var _anfButton    : NSButton!
  @IBOutlet private weak var _qskButton    : NSButton!
  
  @IBOutlet private weak var _txButton      : NSButton!
  @IBOutlet private weak var _alpha         : NSTextField!
  @IBOutlet private weak var _filter        : NSTextField!
  @IBOutlet private weak var _rcvAntenna    : NSPopUpButton!
  @IBOutlet private weak var _xmitAntenna   : NSPopUpButton!
  @IBOutlet private weak var _lock          : NSButton!
  
  @IBOutlet private weak var _sMeter        : NSLevelIndicator!
  
  @IBOutlet weak var _containerView         : NSView!
  @IBOutlet var _tabViewHeight              : NSLayoutConstraint!
  
  private var _tabViewController            : NSTabViewController?
  private var _previousTabIndex             : Int?
  
  //  private var _popoverVc                    : NSViewController?
  //  private var _activeButton                 : NSButton?
  //  private var _audioPopover                 : Any?
  
  private var _position                     = NSPoint(x: 0.0, y: 0.0)
  
  private let kFlagOffset                   : CGFloat = 15.0/2.0
  private let kTabViewOpen                  : CGFloat = 93.0
  private let kTabViewClosed                : CGFloat = 0.0
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    //    view.layer?.backgroundColor = NSColor.darkGray.cgColor
    
    // derive the Slice letter
    if let index = Int(slice!.id), index < FlagViewController.kSliceLetters.count {
      _alpha.stringValue = FlagViewController.kSliceLetters[index]
    } else {
      _alpha.stringValue = "?"
    }
    
    _nbButton.state = slice!.nbEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    _nrButton.state = slice!.nrEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    _anfButton.state = slice!.anfEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    _qskButton.state = slice!.qskEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    
    let width = Float(slice!.filterHigh - slice!.filterLow)/1000.0
    _filter.stringValue = String(format: "%3.1fk", width)
    _filter.toolTip = "Filter"
    
    _rcvAntenna.toolTip = "Receive"
    _xmitAntenna.toolTip = "Transmit"
    
    _lock.state = (slice!.locked ? NSControl.StateValue.on : NSControl.StateValue.off)
    
    // begin observations (slice)
    createObservations(&_observations, object: slice!)
    
    addNotifications()
  }
  
  public override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    
    if segue.identifier!.rawValue == "TabViewEmbed" {
      _tabViewController = segue.destinationController as? NSTabViewController
      
      // give the initially selected tab a reference to the User Defaults
      _tabViewController!.tabView.selectedTabViewItem?.viewController?.representedObject = slice!
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func nbButton(_ sender: NSButton) {
    slice!.nbEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func nrButton(_ sender: NSButton) {
    slice!.nrEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func anfButton(_ sender: NSButton) {
    slice!.anfEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func qskButton(_ sender: NSButton) {
    slice!.qskEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func txButton(_ sender: NSButton) {
    slice!.txEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func lockButton(_ sender: NSButton) {
    slice!.locked = (sender.state == NSControl.StateValue.on)
  }
  
  @IBAction func audButton(_ sender: Any) {
    tabClicked(index: 0)
  }
  
  @IBAction func dspButton(_ sender: Any) {
    tabClicked(index: 1)
  }
  
  @IBAction func modeButton(_ sender: Any) {
    tabClicked(index: 2)
  }
  
  @IBAction func ritButton(_ sender: Any) {
    tabClicked(index: 3)
  }
  
  @IBAction func daxButton(_ sender: Any) {
    tabClicked(index: 4)
  }
  
  private func tabClicked(index: Int) {
    
    let state = (_previousTabIndex, index, _tabViewHeight.constant)
    
    switch state {
      
    case (nil, _, _):
      // NO PREVIOUS TAB - expand it & select tab
      _tabViewController?.selectedTabViewItemIndex = index      
      _tabViewHeight.constant = kTabViewOpen
      view.frame.origin.y = view.frame.origin.y - kTabViewOpen
      
    case (_, _previousTabIndex, kTabViewClosed):
      // SAME TAB AS PREVIOUS, IS COLLAPSED - expand it
      _tabViewHeight.constant = kTabViewOpen
      view.frame.origin.y = view.frame.origin.y - kTabViewOpen
      
    case (_, _previousTabIndex, kTabViewOpen):
      // SAME TAB AS PREVIOUS, IS EXPANDED - collapse it
      _tabViewHeight.constant = kTabViewClosed
      view.frame.origin.y = view.frame.origin.y + kTabViewOpen
      
    case (_, _, 0):
      // DIFFERENT TAB FROM PREVIOUS, IS COLLAPSED - expand it
      _tabViewController?.selectedTabViewItemIndex = index

      _tabViewHeight.constant = kTabViewOpen
      view.frame.origin.y = view.frame.origin.y - kTabViewOpen
      
    default:
      // DIFFERENT TAB FROM PREVIOUS, IS EXPANDED - select it
      _tabViewController?.selectedTabViewItemIndex = index
    }
    // give the selected tab a reference to the User Defaults
    _tabViewController!.tabView.selectedTabViewItem?.viewController?.representedObject = slice!

    _previousTabIndex = index
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
  // MARK: - NEW Observation methods
  
  private var _observations    = [NSKeyValueObservation]()
  
  /// Add observers for Slice properties
  ///
  private func createObservations(_ observations: inout [NSKeyValueObservation], object: xLib6000.Slice ) {
    
    observations = [
      object.observe(\.txEnabled, options: [.new], changeHandler: observer),
      object.observe(\.nbEnabled, options: [.new], changeHandler: observer),
      object.observe(\.nrEnabled, options: [.new], changeHandler: observer),
      object.observe(\.anfEnabled, options: [.new], changeHandler: observer),
      object.observe(\.qskEnabled, options: [.new], changeHandler: observer),
      object.observe(\.filterHigh, options: [.new], changeHandler: observer),
      object.observe(\.filterLow, options: [.new], changeHandler: observer),
      object.observe(\.locked, options: [.new], changeHandler: observer)
    ]
  }
  private func observer(_ object: Any, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._txButton.state = self.slice!.txEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
      self._nbButton.state = self.slice!.nbEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
      self._nrButton.state = self.slice!.nrEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
      self._anfButton.state = self.slice!.anfEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
      self._qskButton.state = self.slice!.qskEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
      
      let width = Float(self.slice!.filterHigh - self.slice!.filterLow)/1000.0
      self._filter.stringValue = String(format: "%3.1fk", width)
      
      self._lock.state = (self.slice!.locked ? NSControl.StateValue.on : NSControl.StateValue.off)
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
      
      // add observations for the needed Meters
      switch meter.name {
        
      case Api.MeterShortName.signalPassband.rawValue:
        
        // S-Meter
        _levelObservation = meter.observe(\.value, options: [.initial, .new]) { (meter, change) in
          
          // process observations of the S-Meter
          DispatchQueue.main.async { [unowned self] in
            self._sMeter.floatValue = meter.value
          }
        }
        
      default:
        break
      }
    }
  }
}
