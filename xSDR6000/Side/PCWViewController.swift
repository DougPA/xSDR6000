//
//  PCWViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/15/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PCWViewController                         : NSViewController {

  @objc dynamic public var radio                : Radio {
    return representedObject as! Radio }

  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
  
}
