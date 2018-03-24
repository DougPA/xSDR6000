//
//  PhoneViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/16/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa

class PhoneViewController                   : NSViewController {
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.layer?.backgroundColor = NSColor.gray.cgColor
  }
  
}
