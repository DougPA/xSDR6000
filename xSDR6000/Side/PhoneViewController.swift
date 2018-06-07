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
  
//  private var _radio                        : Radio!                        // radio class
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    // get references to the Radio & the Equalizers
//    _radio = representedObject as! Radio
    
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
}
