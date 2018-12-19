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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  private let kModel                        = NSUserInterfaceItemIdentifier(rawValue: "Model")
  private let kCallsign                     = NSUserInterfaceItemIdentifier(rawValue: "Callsign")
  private let kNickname                     = NSUserInterfaceItemIdentifier(rawValue: "Nickname")

  // ----------------------------------------------------------------------------
  // MARK: - Action  methods
  
  @IBAction func regionChange(_ sender: NSButton) {
    
    // TODO: add code
    
    Swift.print("radioTabRegionChange")
  }
  
  @IBAction func screensaver(_ sender: NSButton) {
    
    if let radio = Api.sharedInstance.radio {
      
      switch sender.identifier {
      case kModel:
        radio.radioScreenSaver = "model"
        
      case kCallsign:
        radio.radioScreenSaver = "callsign"
        
      case kNickname:
        radio.radioScreenSaver = "nickname"
        
      default:
        fatalError()
      }
    }
  }
}
