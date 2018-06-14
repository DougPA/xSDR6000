//
//  PhoneViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/16/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PhoneViewController                   : NSViewController {
  
  @objc dynamic public var transmit         : Transmit {
    return (representedObject as! Radio).transmit
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
    
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
}
