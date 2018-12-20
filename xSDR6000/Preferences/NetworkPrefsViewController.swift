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
  
  // NOTE:
  //
  //      Most of the fields on this View are setup as Bindings or as User Defined Runtime
  //      Attributes. Those below are the exceptions that required some additionl processing
  //      not available through other methods.
  //
  
  // KVO for bindings
  @objc dynamic var active                  = false                     // enable/disable all controls
  @objc dynamic var radio                   : Radio?

  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  @IBOutlet private weak var _staticRadioButton : NSButton!
  @IBOutlet private weak var _dhcpRadioButton   : NSButton!

  private let kDhcp                         = NSUserInterfaceItemIdentifier(rawValue: "Dhcp")
  private let kStatic                       = NSUserInterfaceItemIdentifier(rawValue: "Static")
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden  methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // check for an active radio
    if let radio = Api.sharedInstance.radio{ self.radio = radio ; setupRadioButtons() ; active = true }
    
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
      if radio!.staticIp.isValidIP4() && radio!.staticNetmask.isValidIP4() && radio!.staticGateway.isValidIP4() {
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

  private func changeNetwork(dhcp: Bool) {
    
    if dhcp {
      // DHCP
      radio?.staticNetParamsReset()
    
    } else {
      radio?.staticNetParamsSet()
    }
    // reboot the radio
    radio?.rebootRequest()
    
    sleep(1)
    
    // perform an orderly shutdown of all the components
    Api.sharedInstance.shutdown(reason: .normal)
    
//    DispatchQueue.main.async {
//      os_log("Application closed by user", log: self._log, type: .info)
      
//      // close the app
//      NSApp.terminate(self)
//    }
  }
  
  func setupRadioButtons() {

    DispatchQueue.main.async { [unowned self] in
      if self.radio!.staticIp == "" && self.radio!.staticNetmask == "" && self.radio!.staticGateway == "" {
        self._dhcpRadioButton.boolState = true
      } else {
        self._staticRadioButton.boolState = true
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
    
    self.radio = note.object as? Radio
    
    setupRadioButtons()
    
    // enable all controls
    active = true
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    active = false
    
    radio = nil
  }
}
