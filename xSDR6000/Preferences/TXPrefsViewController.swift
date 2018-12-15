//
//  TXPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/12/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class TXPrefsViewController                 : NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  // Timings
  @IBOutlet private weak var _accTxCheckbox             : NSButton!
  @IBOutlet private weak var _rcaTx1Checkbox            : NSButton!
  @IBOutlet private weak var _rcaTx2Checkbox            : NSButton!
  @IBOutlet private weak var _rcaTx3Checkbox            : NSButton!
  @IBOutlet private weak var _accTxTextField            : NSTextField!
  @IBOutlet private weak var _rcaTx1TextField           : NSTextField!
  @IBOutlet private weak var _rcaTx2TextField           : NSTextField!
  @IBOutlet private weak var _rcaTx3TextField           : NSTextField!
  @IBOutlet private weak var _txDelayTextField          : NSTextField!
  @IBOutlet private weak var _txTimeoutTextField        : NSTextField!
  @IBOutlet private weak var _txProfilePopUp            : NSPopUpButton!
  @IBOutlet private weak var _txInhibitCheckbox         : NSButton!
  // Interlocks
  @IBOutlet private weak var _rcaInterlockPopup         : NSPopUpButton!
  @IBOutlet private weak var _accessoryInterlockPopup   : NSPopUpButton!
  
  // Misc
  @IBOutlet private weak var _hardwareAlcCheckbox       : NSButton!
  @IBOutlet private weak var _maxPowerTextField         : NSTextField!
  @IBOutlet private weak var _txInWaterfallCheckbox     : NSButton!

  private var _radio                        = Api.sharedInstance.radio
  
  private let kAccTx                        = NSUserInterfaceItemIdentifier(rawValue: "AccTx")
  private let kAccTxDelay                   = NSUserInterfaceItemIdentifier(rawValue: "AccTxDelay")
  private let kRcaTx1                       = NSUserInterfaceItemIdentifier(rawValue: "RcaTx1")
  private let kRcaTx2                       = NSUserInterfaceItemIdentifier(rawValue: "RcaTx2")
  private let kRcaTx3                       = NSUserInterfaceItemIdentifier(rawValue: "RcaTx3")
  private let kTx1Delay                     = NSUserInterfaceItemIdentifier(rawValue: "Tx1Delay")
  private let kTx2Delay                     = NSUserInterfaceItemIdentifier(rawValue: "Tx2Delay")
  private let kTx3Delay                     = NSUserInterfaceItemIdentifier(rawValue: "Tx3Delay")
  private let kTxDelay                      = NSUserInterfaceItemIdentifier(rawValue: "TxDelay")
  private let kTimeout                      = NSUserInterfaceItemIdentifier(rawValue: "Timeout")
  private let kTxInhibit                    = NSUserInterfaceItemIdentifier(rawValue: "TxInhibit")
  private let kRcaInterlocks                = NSUserInterfaceItemIdentifier(rawValue: "RcaInterlocks")
  private let kAccessoryInterlocks          = NSUserInterfaceItemIdentifier(rawValue: "AccessoryInterlocks")
  private let kMaxPower                     = NSUserInterfaceItemIdentifier(rawValue: "MaxPower")
  private let kHardwareAlc                  = NSUserInterfaceItemIdentifier(rawValue: "HardwareAlc")
  private let kTxInWaterfall                = NSUserInterfaceItemIdentifier(rawValue: "TxInWaterfall")
  private let kTxProfile                    = NSUserInterfaceItemIdentifier(rawValue: "TxProfile")
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    view.translatesAutoresizingMaskIntoConstraints = false
//    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // enable/disable all controls
    setControlState( _radio != nil )

    if let radio = _radio { addObservations(radio) }

    // begin receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func checkboxes(_ sender: NSButton) {
    
    switch sender.identifier {
    case kAccTx:
      _radio?.interlock.accTxEnabled = sender.boolState
    case kRcaTx1:
      _radio?.interlock.tx1Enabled = sender.boolState
    case kRcaTx2:
      _radio?.interlock.tx2Enabled = sender.boolState
    case kRcaTx3:
      _radio?.interlock.tx3Enabled = sender.boolState
    case kTxInhibit:
      break
//      _radio?.interlock.txAllowed = !sender.boolState
    case kHardwareAlc:
      _radio?.transmit.hwAlcEnabled = sender.boolState
    case kTxInWaterfall:
      _radio?.transmit.txInWaterfallEnabled = sender.boolState
    default:
      fatalError()
    }
  }

  @IBAction func textFields(_ sender: NSTextField) {
    
    switch sender.identifier {
    case kAccTxDelay:
      _radio?.interlock.accTxDelay = sender.integerValue
    case kTx1Delay:
      _radio?.interlock.tx1Delay = sender.integerValue
    case kTx2Delay:
      _radio?.interlock.tx2Delay = sender.integerValue
    case kTx3Delay:
      _radio?.interlock.tx3Delay = sender.integerValue
    case kTxDelay:
      break
//      _radio?.interlock.txDelay = sender.integerValue
    case kTimeout:
      _radio?.interlock.timeout = sender.integerValue
    case kMaxPower:
      _radio?.transmit.maxPowerLevel = sender.integerValue
    default:
      fatalError()
    }
  }
  
  @IBAction func popups(_ sender: NSPopUpButton) {
    
    switch sender.identifier {
    case kTxProfile:
      _radio?.profiles[Profile.kTx]!.selection = sender.titleOfSelectedItem!
    case kRcaInterlocks:
      break
    case kAccessoryInterlocks:
      break
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
    
    DispatchQueue.main.async { [weak self] in
      // Timings
      self?._accTxCheckbox.isEnabled = state
      self?._rcaTx1Checkbox.isEnabled = state
      self?._rcaTx2Checkbox.isEnabled = state
      self?._rcaTx3Checkbox.isEnabled = state
      self?._accTxTextField.isEnabled = state
      self?._rcaTx1TextField.isEnabled = state
      self?._rcaTx2TextField.isEnabled = state
      self?._rcaTx3TextField.isEnabled = state
      self?._txDelayTextField.isEnabled = state
      self?._txInhibitCheckbox.isEnabled = state
      self?._txProfilePopUp.isEnabled = state
      self?._txTimeoutTextField.isEnabled = state

      // Interlocks
      self?._accessoryInterlockPopup.isEnabled = state
      self?._rcaInterlockPopup.isEnabled = state
      
      // Misc
      self?._hardwareAlcCheckbox.isEnabled = state
      self?._maxPowerTextField.isEnabled = state
      self?._txInWaterfallCheckbox.isEnabled = state
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {
    
    _radio = radio
    
    // Interlock observations
    _observations.append( radio.interlock!.observe(\.accTxDelay, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.accTxEnabled, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.txAllowed, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.txDelay, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.timeout, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx1Delay, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx2Delay, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx3Delay, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx1Enabled, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx2Enabled, options: [.initial, .new], changeHandler: interlockChange) )
    _observations.append( radio.interlock!.observe(\.tx3Enabled, options: [.initial, .new], changeHandler: interlockChange) )
    
    // Profile observations
    _observations.append( radio.profiles[Profile.kTx]!.observe(\.list, options: [.initial, .new], changeHandler: profileChange) )
    _observations.append( radio.profiles[Profile.kTx]!.observe(\.selection, options: [.initial, .new], changeHandler: profileChange) )

    _observations.append( radio.transmit!.observe(\.hwAlcEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.maxPowerLevel, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.txInWaterfallEnabled, options: [.initial, .new], changeHandler: transmitChange) )

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
  /// Update all Interlock control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func interlockChange(_ interlock: Interlock, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      // Timings
      self?._accTxTextField.integerValue = interlock.accTxDelay
      self?._accTxCheckbox.boolState = interlock.accTxEnabled
      self?._txInhibitCheckbox.boolState = !interlock.txAllowed
      self?._txDelayTextField.integerValue = interlock.txDelay
      self?._txTimeoutTextField.integerValue = interlock.timeout
      self?._rcaTx1TextField.integerValue = interlock.tx1Delay
      self?._rcaTx2TextField.integerValue = interlock.tx2Delay
      self?._rcaTx3TextField.integerValue = interlock.tx3Delay
      self?._rcaTx1Checkbox.boolState = interlock.tx1Enabled
      self?._rcaTx2Checkbox.boolState = interlock.tx2Enabled
      self?._rcaTx3Checkbox.boolState = interlock.tx3Enabled
    }
  }
  /// Update all Profile control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func profileChange(_ profile: Profile, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      // Timings
      self?._txProfilePopUp.removeAllItems()
      self?._txProfilePopUp.addItems(withTitles: profile.list)
      self?._txProfilePopUp.selectItem(withTitle: profile.selection)
    }
  }
  /// Update all Transmit control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func transmitChange(_ transmit: Transmit, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._hardwareAlcCheckbox.boolState = transmit.hwAlcEnabled
      self?._maxPowerTextField.integerValue = transmit.maxPowerLevel
      self?._txInWaterfallCheckbox.boolState = transmit.txInWaterfallEnabled
    }
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
  /// - Parameter note:             a Notification instance
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
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    setControlState(false)
    
    // invalidate & remove observations
    invalidateObservations()
    
    _radio = nil
  }
}
