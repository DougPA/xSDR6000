//
//  ColorsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/7/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa

final class ColorsViewController            : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidDisappear() {
    
    // close the ColorPicker (if open)
    if NSColorPanel.shared.isVisible {
      NSColorPanel.shared.performClose(nil)
    }
  }
  
}
