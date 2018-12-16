//
//  RadioPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/15/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa

class RadioPrefsViewController: NSViewController {

  
  private let kModel                        = NSUserInterfaceItemIdentifier(rawValue: "Model")
  private let kCallsign                     = NSUserInterfaceItemIdentifier(rawValue: "Callsign")
  private let kNickname                     = NSUserInterfaceItemIdentifier(rawValue: "Nickname")

  @IBAction func radioButtons(_ sender: NSButton) {
    
    switch sender.identifier {
    case kModel:
      break
    case kCallsign:
      break
    case kNickname:
      break
    default:
      fatalError()
    }
    Swift.print("Button = \(sender.identifier)")
  }
  
}
