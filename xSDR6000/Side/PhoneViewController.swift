//
//  PhoneViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/16/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PhoneViewController                   : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _carrierLevel        : NSSlider!
  @IBOutlet private weak var _voxLevel            : NSSlider!
  @IBOutlet private weak var _voxDelay            : NSSlider!
  @IBOutlet private weak var _companderLevel      : NSSlider!  
  @IBOutlet private weak var _voxEnabled          : NSButton!
  @IBOutlet private weak var _companderEnabled    : NSButton!
  @IBOutlet private weak var _txFilterLow         : NSTextField!
  @IBOutlet private weak var _txFilterLowStepper  : NSStepper!
  
  @IBOutlet private weak var _txFilterHigh        : NSTextField!
  @IBOutlet private weak var _txFilterHighStepper : NSStepper!
  
  private var _transmit                     : Transmit?
  
  private let kVox                          = NSUserInterfaceItemIdentifier(rawValue: "Vox")
  private let kDexp                         = NSUserInterfaceItemIdentifier(rawValue: "Dexp")
  private let kTxLowStepper                 = NSUserInterfaceItemIdentifier(rawValue: "TxLowStepper")
  private let kTxHighStepper                = NSUserInterfaceItemIdentifier(rawValue: "TxHighStepper")
  private let kFilterStep                   = 10
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // disable all controls
    setControlState(false)
    
    // begin receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier {
    case kDexp:
      _transmit?.companderEnabled = sender.boolState
    case kVox:
      _transmit?.voxEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  /// Respond to one of the steppers
  ///
  /// - Parameter sender:             the stepper
  ///
@IBAction func steppers(_ sender: NSStepper) {

    switch sender.identifier {
    case kTxHighStepper:
      _transmit?.txFilterHigh += Int(sender.increment)
    case kTxLowStepper:
      _transmit?.txFilterLow += Int(sender.increment)
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [unowned self] in
      // Buttons
      self._voxEnabled.isEnabled = state
      self._companderEnabled.isEnabled = state
      // Sliders
      self._carrierLevel.isEnabled = state
      self._voxLevel.isEnabled = state
      self._voxDelay.isEnabled = state
      self._companderLevel.isEnabled = state
      // TextFields
      self._txFilterLow.isEnabled = state
      self._txFilterHigh.isEnabled = state
      // Steppers
      self._txFilterLowStepper.isEnabled = state
      self._txFilterHighStepper.isEnabled = state
    }
  }
  /// Update all control values
  ///
  /// - Parameter eq:               the Equalizer
  ///
  private func populateControls(_ transmit: Transmit) {
    
    DispatchQueue.main.async { [unowned self] in
      // Buttons
      self._voxEnabled.state = transmit.voxEnabled.state
      self._companderEnabled.state = transmit.companderEnabled.state
      // SLiders
      self._carrierLevel.integerValue = transmit.carrierLevel
      self._voxLevel.integerValue = transmit.voxLevel
      self._voxDelay.integerValue = transmit.voxDelay
      self._companderLevel.integerValue = transmit.companderLevel
      // Textfields
      self._txFilterLow.integerValue = transmit.txFilterLow
      self._txFilterHigh.integerValue = transmit.txFilterHigh
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations of parameters
  ///
  private func addObservations(_ radio: Radio) {
    
    if let transmit = radio.transmit {
      _transmit = transmit
      
      _observations.append( transmit.observe(\.carrierLevel, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.voxEnabled, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.voxLevel, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.voxDelay, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.companderEnabled, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.companderLevel, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.txFilterLow, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( transmit.observe(\.txFilterHigh, options: [.initial, .new], changeHandler: paramChange) )
    }
  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(remove: Bool = true) {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // if specified, remove the tokens
    if remove { _observations.removeAll() }
  }
  /// Respond to changes in parameters
  ///
  /// - Parameters:
  ///   - object:                       a Transmit
  ///   - change:                       the change
  ///
  private func paramChange(_ transmit: Transmit, _ change: Any) {
    // update the control values
    populateControls(transmit)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded)
    
    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved)
  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func radioHasBeenAdded(_ note: Notification) {
    
    if let radio = note.object as? Radio {
      
      // begin observing parameters
      addObservations(radio)

      // enable all controls
      setControlState(true)
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    setControlState(false)
    
    // invalidate & remove observations
    invalidateObservations()
  }
}
