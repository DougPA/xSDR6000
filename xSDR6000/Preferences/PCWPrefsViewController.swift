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
  // MARK: - Private properties
  
  @IBOutlet private weak var _cwLowerRadioButton    : NSButton!
  @IBOutlet private weak var _cwUpperRadioButton    : NSButton!
  @IBOutlet private weak var _iambicARadioButton    : NSButton!
  @IBOutlet private weak var _iambicBRadioButton    : NSButton!
  
  private let kCwSidebandLower              = NSUserInterfaceItemIdentifier(rawValue: "CwSidebandLower")
  private let kCwSidebandUpper              = NSUserInterfaceItemIdentifier(rawValue: "CwSidebandUpper")
  private let kIambicA                      = NSUserInterfaceItemIdentifier(rawValue: "IambicA")
  private let kIambicB                      = NSUserInterfaceItemIdentifier(rawValue: "IambicB")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let radio = Api.sharedInstance.radio { self.radio = radio ; setupButtons() }
    
    // begin receiving notifications
    addNotifications()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func iambicMode(_ sender: NSButton) {
    
    switch sender.identifier {
    case kIambicA:
      radio?.transmit.cwIambicMode = 0
    case kIambicB:
      radio?.transmit.cwIambicMode = 1
    default:
      fatalError()
    }
  }
  
  @IBAction func cwSideband(_ sender: NSButton) {
    
    switch sender.identifier {
    case kCwSidebandUpper:
      radio?.transmit.cwlEnabled = false
    case kCwSidebandLower:
      radio?.transmit.cwlEnabled = true
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Methods
  
  func setupButtons() {
    
    active = true
    
    DispatchQueue.main.async { [unowned self] in
      // Iambic A/B
      if self.radio!.transmit.cwIambicMode == 0 {
        // A Mode
        self._iambicARadioButton.boolState = true
      
      } else {
        // B Mode
        self._iambicBRadioButton.boolState = true
      }
      // CW Upper/Lower sideband
      if self.radio!.transmit.cwlEnabled {
        // Lower
        self._cwLowerRadioButton.boolState = true
      
      } else {
        // Upper
        self._cwUpperRadioButton.boolState = true
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
    
    setupButtons()
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    self.radio = nil
    active = false
  }
}
