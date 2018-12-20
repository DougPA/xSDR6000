//
//  FiltersPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/20/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class FiltersPrefsViewController: NSViewController {

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
  // MARK: - Overridden  methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // check for an active radio
    if let radio = Api.sharedInstance.radio{ self.radio = radio ; active = true }
    
    // start receiving notifications
    addNotifications()
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
      
      self.radio = radio
      
      // enable all controls
      active = true
    }
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
