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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  private let kDhcp                         = NSUserInterfaceItemIdentifier(rawValue: "Dhcp")
  private let kStatic                       = NSUserInterfaceItemIdentifier(rawValue: "Static")

  @objc dynamic var staticIpAddress: String {
    get { return Api.sharedInstance.radio?.staticIp ?? "" }
    set { Api.sharedInstance.radio?.staticIp = newValue }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden  methods
  
  override func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey inKey: String) throws {
    // test here, replace the dummy test below with something useful

    Swift.print("validateValue")

    if let s = ioValue.pointee as? String {
      if !s.isValidIP4() {
        throw NSError(domain: "xDSR6000", code: 100, userInfo: [NSLocalizedDescriptionKey: "\(s) is an Invalid IPV4 Address"])
      }
    }
    Swift.print("staticIp = \(Api.sharedInstance.radio?.staticIp)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action  methods
  
  @IBAction func networkTabApply(_ sender: NSButton) {
    
    // TODO: add code
    
    Swift.print("networkTabApply")
  }
  
  @IBAction func networkTabDhcpStatic(_ sender: NSButton) {
    
    if let radio = Api.sharedInstance.radio {
      
      switch sender.identifier {
      case kDhcp:
        if sender.boolState { radio.staticNetParamsReset() }
        
      case kStatic:
        if sender.boolState { radio.staticNetParamsSet()}
        
      default:
        fatalError()
      }
    }
  }
}
