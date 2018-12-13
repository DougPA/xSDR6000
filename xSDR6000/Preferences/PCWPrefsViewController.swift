//
//  PCWPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/11/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000


class PCWPrefsViewController                : NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // Microphone
  @IBOutlet private weak var _micBiasCheckbox     : NSButton!
  @IBOutlet private weak var _micBoostCheckbox    : NSButton!
  @IBOutlet private weak var _micMetInRxCheckbox  : NSButton!
  
  // CW
  @IBOutlet private weak var _cwLowerRadioButton    : NSButton!
  @IBOutlet private weak var _cwUpperRadioButton    : NSButton!
  @IBOutlet private weak var _cwxSyncCheckbox       : NSButton!
  @IBOutlet private weak var _iambicCheckbox        : NSButton!
  @IBOutlet private weak var _iambicARadioButton    : NSButton!
  @IBOutlet private weak var _iambicBRadioButton    : NSButton!
  @IBOutlet private weak var _swapPaddlesCheckbox   : NSButton!
  
  // Digital
  @IBOutlet private weak var _rttyMarkTextField     : NSTextField!
  
  private var _radio                        = Api.sharedInstance.radio

  private let kCwSidebandLower              = NSUserInterfaceItemIdentifier(rawValue: "CwSidebandLower")
  private let kCwSidebandUpper              = NSUserInterfaceItemIdentifier(rawValue: "CwSidebandUpper")
  private let kCwxSync                      = NSUserInterfaceItemIdentifier(rawValue: "CwxSync")
  private let kIambic                       = NSUserInterfaceItemIdentifier(rawValue: "Iambic")
  private let kIambicA                      = NSUserInterfaceItemIdentifier(rawValue: "IambicA")
  private let kIambicB                      = NSUserInterfaceItemIdentifier(rawValue: "IambicB")
  private let kMetInRx                      = NSUserInterfaceItemIdentifier(rawValue: "MetInRx")
  private let kMicBias                      = NSUserInterfaceItemIdentifier(rawValue: "MicBias")
  private let kMicBoost                     = NSUserInterfaceItemIdentifier(rawValue: "MicBoost")
  private let kSwapPaddles                  = NSUserInterfaceItemIdentifier(rawValue: "SwapPaddles")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // enable/disable all controls
    setControlState( _radio != nil )
    
    if let radio = _radio { addObservations(radio) }
    
    // begin receiving notifications
    addNotifications()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func checkBoxes(_ sender: NSButton) {
    
    switch sender.identifier {
    case kMicBias:
      _radio?.transmit.micBiasEnabled = sender.boolState
    case kMicBoost:
      _radio?.transmit.micBoostEnabled = sender.boolState
    case kMetInRx:
      _radio?.transmit.metInRxEnabled = sender.boolState
    case kIambic:
      _radio?.transmit.cwIambicEnabled = sender.boolState
    case kSwapPaddles:
      _radio?.transmit.cwSwapPaddles = sender.boolState
    case kCwxSync:
      _radio?.transmit.cwSyncCwxEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  @IBAction func iambicMode(_ sender: NSButton) {
    
    switch sender.identifier {
    case kIambicA:
      _radio?.transmit.cwIambicMode = 0
    case kIambicB:
      _radio?.transmit.cwIambicMode = 1
    default:
      fatalError()
    }
  }
  
  @IBAction func cwSideband(_ sender: NSButton) {
    
    switch sender.identifier {
    case kCwSidebandUpper:
      _radio?.transmit.cwlEnabled = false
    case kCwSidebandLower:
      _radio?.transmit.cwlEnabled = true
    default:
      fatalError()
    }
  }
  @IBAction func rttyMarkDefault(_ sender: NSTextField) {
    
    _radio?.rttyMark = sender.integerValue
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [weak self] in
      // Mic checkboxes
      self?._micBiasCheckbox.isEnabled = state
      self?._micBoostCheckbox.isEnabled = state
      self?._micMetInRxCheckbox.isEnabled = state
      
      // CW Checkboxes
      self?._iambicCheckbox.isEnabled = state
      self?._swapPaddlesCheckbox.isEnabled = state
      self?._cwxSyncCheckbox.isEnabled = state
      
      // CW RadioButtons
      self?._iambicARadioButton.isEnabled = state
      self?._iambicBRadioButton.isEnabled = state
      self?._cwUpperRadioButton.isEnabled = state
      self?._cwLowerRadioButton.isEnabled = state
      
      // Digital textfield
      self?._rttyMarkTextField.isEnabled = state
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {
    
    _radio = radio
    
    // Transmit observations
    _observations.append( radio.transmit!.observe(\.micBiasEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.micBoostEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.metInRxEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.cwIambicEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.cwIambicMode, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.cwSwapPaddles, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.cwlEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.cwSyncCwxEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.observe(\.rttyMark, options: [.initial, .new], changeHandler: radioChange) )
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
  /// Update all Transmit control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func transmitChange(_ transmit: Transmit, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      // Mic checkboxes
      self?._micBiasCheckbox.boolState = transmit.micBiasEnabled
      self?._micBoostCheckbox.boolState = transmit.micBoostEnabled
      self?._micMetInRxCheckbox.boolState = transmit.metInRxEnabled

      // CW Checkboxes
      self?._iambicCheckbox.boolState = transmit.cwlEnabled
      self?._swapPaddlesCheckbox.boolState = transmit.cwSwapPaddles
      self?._cwxSyncCheckbox.boolState = transmit.cwSyncCwxEnabled
      
      // CW RadioButtons
      self?._iambicARadioButton.boolState = (transmit.cwIambicMode == 0)
      self?._iambicBRadioButton.boolState = (transmit.cwIambicMode == 1)
      self?._cwUpperRadioButton.boolState = transmit.cwlEnabled == false
      self?._cwLowerRadioButton.boolState = transmit.cwlEnabled == true
    }
  }
  /// Update all Radio control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func radioChange(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      // Digital textfield
      self?._rttyMarkTextField.integerValue = radio.rttyMark
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
