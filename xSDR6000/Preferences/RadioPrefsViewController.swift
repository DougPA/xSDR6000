//
//  RadioPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/15/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class RadioPrefsViewController: NSViewController {

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
  
  private let kModel                        = NSUserInterfaceItemIdentifier(rawValue: "Model")
  private let kCallsign                     = NSUserInterfaceItemIdentifier(rawValue: "Callsign")
  private let kNickname                     = NSUserInterfaceItemIdentifier(rawValue: "Nickname")
  
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
  // MARK: - Action  methods
  
  @IBAction func regionChange(_ sender: NSButton) {
    
    // TODO: add code
    
    notImplemented(sender.title).beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in } )
  }
  
  @IBAction func screensaver(_ sender: NSButton) {
    
    switch sender.identifier {
    case kModel:
      radio?.radioScreenSaver = "model"
      
    case kCallsign:
      radio?.radioScreenSaver = "callsign"
      
    case kNickname:
      radio?.radioScreenSaver = "nickname"
      
    default:
      fatalError()
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
