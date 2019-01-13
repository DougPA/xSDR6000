//
//  NetworkPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/18/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class NetworkPrefsViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  @IBOutlet private weak var _ipAddressTextField        : NSTextField!
  @IBOutlet private weak var _macAddressTextField       : NSTextField!
  @IBOutlet private weak var _netMaskTextField          : NSTextField!
  @IBOutlet private weak var _staticIpAddressTextField  : NSTextField!
  @IBOutlet private weak var _staticMaskTextField       : NSTextField!
  @IBOutlet private weak var _staticGatewayTextField    : NSTextField!
  
  @IBOutlet private weak var _enforcePrivateIpCheckbox  : NSButton!
  
  @IBOutlet private weak var _staticRadioButton         : NSButton!
  @IBOutlet private weak var _dhcpRadioButton           : NSButton!

  @IBOutlet private weak var _applyButton               : NSButton!
  
  private var _radio                            : Radio?
  private var _observations                     = [NSKeyValueObservation]()

  // ----------------------------------------------------------------------------
  // MARK: - Overridden  methods
  
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
  // MARK: - Action  methods
  
  @IBAction func apply(_ sender: NSButton) {
    
    if _dhcpRadioButton.boolState {
      // DHCP
      changeNetwork(dhcp: true)
      
    } else {
      // Static, are the values valid?
      if _radio!.staticIp.isValidIP4() && _radio!.staticNetmask.isValidIP4() && _radio!.staticGateway.isValidIP4() {
        // YES, make the change
        changeNetwork(dhcp: false)
      } else {
        // NO, warn the user
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "One or more Invalid Static Values"
        alert.informativeText = "Verify that all are valid IPV4 addresses"
        alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in })
      }
    }
  }
  
  @IBAction func networkTabDhcpStatic(_ sender: NSButton) {
    // no action required
    // required for DHCP / STATIC buttons to function as "Radio Buttons"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  methods
  
  /// Enable / Disable controls
  ///
  /// - Parameter status:             true = enable
  ///
  private func enableControls(_ state: Bool = true) {

    if state {
      addObservations()
    } else {
      removeObservations()
    }
    DispatchQueue.main.async { [weak self] in
      self?._staticRadioButton.isEnabled = state
      self?._dhcpRadioButton.isEnabled = state
      
      self?._staticIpAddressTextField.isEnabled = state
      self?._staticMaskTextField.isEnabled = state
      self?._staticGatewayTextField.isEnabled = state
      self?._enforcePrivateIpCheckbox.isEnabled = state
      
      self?._applyButton.isEnabled = state
    }
  }

  /// Change between DHCP and Static
  ///
  /// - Parameter dhcp:               true = DHCP
  ///
  private func changeNetwork(dhcp: Bool) {
    
    if dhcp {
      // DHCP
      _radio?.staticNetParamsReset()
    
    } else {
      _radio?.staticNetParamsSet()
    }
    // reboot the radio
    _radio?.rebootRequest()
    
    sleep(1)
    
    // perform an orderly shutdown of all the components
    Api.sharedInstance.shutdown(reason: .normal)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _radio!.observe(\.ipAddress, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.macAddress, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.netmask, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.enforcePrivateIpEnabled, options: [.initial, .new], changeHandler: radioHandler(_:_:)),

      _radio!.observe(\.staticIp, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.staticNetmask, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.staticGateway, options: [.initial, .new], changeHandler: radioHandler(_:_:))
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
  ///   - profile:                  the Radio being observed
  ///   - change:                   the change
  ///
  private func radioHandler(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._ipAddressTextField.stringValue = radio.ipAddress
      self?._macAddressTextField.stringValue = radio.macAddress
      self?._netMaskTextField.stringValue = radio.netmask
      self?._staticIpAddressTextField.stringValue = radio.staticIp
      self?._staticMaskTextField.stringValue = radio.staticNetmask
      self?._staticGatewayTextField.stringValue = radio.staticGateway

      self?._enforcePrivateIpCheckbox.boolState = radio.enforcePrivateIpEnabled
      
      if radio.staticIp == "" && radio.staticNetmask == "" && radio.staticGateway == "" {
        self?._dhcpRadioButton.boolState = true
      } else {
        self?._staticRadioButton.boolState = true
      }
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
