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

  // NOTE:
  //
  //      Most of the fields on this View are setup as Bindings or as User Defined Runtime
  //      Attributes. Those below are the exceptions that required some additionl processing
  //      not available through other methods.
  //

  // KVO for bindings
  @objc dynamic var active                  = false                     // enable/disable all controls
  @objc dynamic var radio                   : Radio?
  @objc dynamic var txProfile               : Profile?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  // Interlocks
  @IBOutlet private weak var _rcaInterlockPopup         : NSPopUpButton!
  @IBOutlet private weak var _accessoryInterlockPopup   : NSPopUpButton!
  
  
  private let kRcaInterlocks                = NSUserInterfaceItemIdentifier(rawValue: "RcaInterlocks")
  private let kAccessoryInterlocks          = NSUserInterfaceItemIdentifier(rawValue: "AccessoryInterlocks")
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    // check for an active radio
    if let radio = Api.sharedInstance.radio{ self.radio = radio ; setupKVO(enable: true) }
    
    // start receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func popups(_ sender: NSPopUpButton) {
    
    switch sender.identifier {
    case kRcaInterlocks:
      switch sender.selectedItem?.identifier?.rawValue {
      case "RcaDisabled":
        radio?.interlock.rcaTxReqEnabled = false
      case "RcaLow":
        radio?.interlock.rcaTxReqEnabled = true
        radio?.interlock.rcaTxReqPolarity = false

      case "RcaHigh":
        radio?.interlock.rcaTxReqEnabled = true
        radio?.interlock.rcaTxReqPolarity = true
      default:
        fatalError()
      }
    case kAccessoryInterlocks:
      switch sender.selectedItem?.identifier?.rawValue {
      case "AccDisabled":
        radio?.interlock.accTxReqEnabled = false
      case "AccLow":
        radio?.interlock.accTxReqEnabled = true
        radio?.interlock.accTxReqPolarity = false
        
      case "AccHigh":
        radio?.interlock.accTxReqEnabled = true
        radio?.interlock.accTxReqPolarity = true
      default:
        fatalError()
      }
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Methods
  
  /// Enable/Disable controls & populate KVO fields
  ///
  /// - Parameter enable:             enable/disable
  ///
  private func setupKVO(enable: Bool) {

    if enable {
      // popultae KVO field
      txProfile = radio?.profiles[Profile.kTx]
    
      // enable all controls
      active = true
    
    } else {
      
      // disable all controls
      active = false
      
      // release KVO field
      txProfile = nil
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
    
    radio = note.object as? Radio
    
    setupKVO(enable: true)
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    setupKVO(enable: false)

    radio = nil
  }
}
