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

  @objc dynamic var txProfile               : Profile?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  @IBOutlet private weak var _accTxCheckbox             : NSButton!
  @IBOutlet private weak var _rcaTx1Checkbox            : NSButton!
  @IBOutlet private weak var _rcaTx2Checkbox            : NSButton!
  @IBOutlet private weak var _rcaTx3Checkbox            : NSButton!
  @IBOutlet private weak var _txInhibitCheckbox         : NSButton!

  @IBOutlet private weak var _accTxTextField            : NSTextField!
  @IBOutlet private weak var _rcaTx1TextField           : NSTextField!
  @IBOutlet private weak var _rcaTx2TextField           : NSTextField!
  @IBOutlet private weak var _rcaTx3TextField           : NSTextField!
  @IBOutlet private weak var _txDelayTextField          : NSTextField!
  @IBOutlet private weak var _txTimeoutTextField        : NSTextField!
  @IBOutlet private weak var _maxPowerTextField         : NSTextField!

  @IBOutlet private weak var _txProfilePopUp            : NSPopUpButton!
  @IBOutlet private weak var _rcaInterlockPopup         : NSPopUpButton!
  @IBOutlet private weak var _accInterlockPopup         : NSPopUpButton!
  
  @IBOutlet private weak var _maxPowerSlider            : NSSlider!
  @IBOutlet private weak var _hardWareAlcCheckbox       : NSButton!
  @IBOutlet private weak var _showTxInWaterfallCheckbox : NSButton!
  
  private var _radio                        : Radio?
  private var _interlock                    : Interlock? { return _radio!.interlock }
  private var _transmit                     : Transmit? { return _radio!.transmit }
  private var _txProfile                    : Profile? { return _radio!.profiles[Profile.kTx] }
  private var _observations                 = [NSKeyValueObservation]()

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
    
    // check for an active radio
    if let radio = Api.sharedInstance.radio { _radio = radio ; enableControls(true) }
    
    // start receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Power slider
  ///
  /// - Parameter sender:             the slider
  ///
  @IBAction func powerSlider(_ sender: NSSlider) {

    _transmit?.maxPowerLevel = sender.integerValue
    _maxPowerTextField.integerValue = sender.integerValue
  }
  /// Respond to a checkbox
  ///
  /// - Parameter sender:             the checkbox
  ///
  @IBAction func checkBoxes(_ sender: NSButton) {
    
    switch sender.identifier?.rawValue {
    case "AccTx":
      _interlock!.accTxEnabled = sender.boolState
    case "RcaTx1":
      _interlock!.tx1Enabled = sender.boolState
    case "RcaTx2":
      _interlock!.tx2Enabled = sender.boolState
    case "RcaTx3":
      _interlock!.tx3Enabled = sender.boolState
    case "TxInhibit":
      _transmit?.inhibit = sender.boolState
    case "HardwareAlc":
      _transmit?.hwAlcEnabled = sender.boolState
    case "TxInWaterfall":
      _transmit?.txInWaterfallEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  /// Respond to a text field
  ///
  /// - Parameter sender:             the textfield
  ///
  @IBAction func textFields(_ sender: NSTextField) {
    
    switch sender.identifier?.rawValue {
    case "AccTxDelay":
      _interlock!.accTxDelay = sender.integerValue
    case "Tx1Delay":
      _interlock!.tx1Delay = sender.integerValue
    case "Tx2Delay":
      _interlock!.tx2Delay = sender.integerValue
    case "Tx3Delay":
      _interlock!.tx3Delay = sender.integerValue
    case "TxDelay":
      _interlock!.txDelay = sender.integerValue
    case "Timeout":
      _interlock!.timeout = sender.integerValue
    default:
      fatalError()
    }
  }
  /// Respond to a popup button
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func popups(_ sender: NSPopUpButton) {
    
    switch sender.identifier!.rawValue {
    
    case "TxProfile":
      _txProfile!.selection = sender.titleOfSelectedItem!
    
    case "RcaInterlocks":
      switch sender.selectedItem?.identifier?.rawValue {
      case "RcaDisabled":
        _interlock!.rcaTxReqEnabled = false
      case "RcaLow":
        _interlock!.rcaTxReqEnabled = true
        _interlock!.rcaTxReqPolarity = false
      case "RcaHigh":
        _interlock!.rcaTxReqEnabled = true
        _interlock!.rcaTxReqPolarity = true
      default:
        fatalError()
      }
    
    case "AccessoryInterlocks":
      switch sender.selectedItem?.identifier?.rawValue {
      case "AccDisabled":
        _interlock!.accTxReqEnabled = false
      case "AccLow":
        _interlock!.accTxReqEnabled = true
        _interlock!.accTxReqPolarity = false
        
      case "AccHigh":
        _interlock!.accTxReqEnabled = true
        _interlock!.accTxReqPolarity = true
      default:
        fatalError()
      }
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable controls
  ///
  /// - Parameter status:             true = enable
  ///
  private func enableControls(_ state: Bool = true) {
    
    if state {
      _txProfilePopUp.removeAllItems()
      _txProfilePopUp.addItems(withTitles: _txProfile!.list)
      
      addObservations()
    } else {
      
      removeObservations()
    }
    _accTxCheckbox.isEnabled = state
    _rcaTx1Checkbox.isEnabled = state
    _rcaTx2Checkbox.isEnabled = state
    _rcaTx3Checkbox.isEnabled = state
    _txInhibitCheckbox.isEnabled = state
    _hardWareAlcCheckbox.isEnabled = state
    _showTxInWaterfallCheckbox.isEnabled = state

    _accTxTextField.isEnabled = state
    _rcaTx1TextField.isEnabled = state
    _rcaTx2TextField.isEnabled = state
    _rcaTx3TextField.isEnabled = state
    _txDelayTextField.isEnabled = state
    _txTimeoutTextField.isEnabled = state

    _txProfilePopUp.isEnabled = state
    _rcaInterlockPopup.isEnabled = state
    _accInterlockPopup.isEnabled = state

    _maxPowerSlider.isEnabled = state
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {

    _observations = [
      _interlock!.observe(\.accTxEnabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.accTxDelay, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.timeout, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx1Enabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx2Enabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx3Enabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.accTxDelay, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx1Delay, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx2Delay, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.tx3Delay, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.rcaTxReqEnabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      _interlock!.observe(\.accTxReqEnabled, options: [.initial, .new], changeHandler: interlockHandler(_:_:)),
      
      _transmit!.observe(\.inhibit, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.maxPowerLevel, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.txInWaterfallEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.hwAlcEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),

      _txProfile!.observe(\.selection, options: [.initial, .new], changeHandler: profileHandler(_:_:))
    ]
  }
  /// Remove observations
  ///
  func removeObservations() {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // remove the tokens
    _observations.removeAll()
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - profile:                  the Profile being observed
  ///   - change:                   the change
  ///
  private func profileHandler(_ profile: Profile, _ change: Any) {

    DispatchQueue.main.async { [weak self] in
      self?._txProfilePopUp.selectItem(withTitle: profile.selection)
    }
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - interlock:                the Interlock being observed
  ///   - change:                   the change
  ///
  private func interlockHandler(_ interlock: Interlock, _ change: Any) {

    DispatchQueue.main.async { [weak self] in
      self?._accTxCheckbox.boolState = interlock.accTxEnabled
      self?._rcaTx1Checkbox.boolState = interlock.tx1Enabled
      self?._rcaTx2Checkbox.boolState = interlock.tx2Enabled
      self?._rcaTx3Checkbox.boolState = interlock.tx3Enabled

      self?._accTxTextField.integerValue = interlock.accTxDelay
      self?._txDelayTextField.integerValue = interlock.txDelay
      self?._rcaTx1TextField.integerValue = interlock.tx1Delay
      self?._rcaTx2TextField.integerValue = interlock.tx2Delay
      self?._rcaTx3TextField.integerValue = interlock.tx3Delay
      self?._txTimeoutTextField.integerValue = interlock.timeout

      if interlock.rcaTxReqEnabled {
        let selection = interlock.rcaTxReqPolarity ? "Active High" : "Active Low"
        self?._rcaInterlockPopup.selectItem(withTitle: selection)
      } else {
        self?._rcaInterlockPopup.selectItem(withTitle: "Disabled")
      }

      if interlock.accTxReqEnabled {
        let selection = interlock.accTxReqPolarity ? "Active High" : "Active Low"
        self?._accInterlockPopup.selectItem(withTitle: selection)
      } else {
        self?._accInterlockPopup.selectItem(withTitle: "Disabled")
      }
    }
  }
    
  /// Process observations
  ///
  /// - Parameters:
  ///   - transmit:                 the Transmit being observed
  ///   - change:                   the change
  ///
  private func transmitHandler(_ transmit: Transmit, _ change: Any) {

    DispatchQueue.main.async { [unowned self] in
      self._txInhibitCheckbox.boolState = transmit.inhibit
      self._showTxInWaterfallCheckbox.boolState = transmit.txInWaterfallEnabled
      self._hardWareAlcCheckbox.boolState = transmit.hwAlcEnabled

      self._maxPowerSlider.integerValue = transmit.maxPowerLevel
      self._maxPowerTextField.integerValue = transmit.maxPowerLevel
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
    
    _radio = note.object as? Radio
    
    // enable controls
    enableControls()
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable controls
    enableControls(false)
    
    _radio = nil
  }
}
