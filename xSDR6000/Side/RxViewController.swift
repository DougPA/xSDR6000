//
//  RxViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/26/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa

class RxViewController                      : NSViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
}
