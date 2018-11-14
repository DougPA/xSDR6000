//
//  ControlsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/8/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class ControlsViewController: NSTabViewController {

  @objc dynamic weak var slice              : xLib6000.Slice?
  @objc dynamic weak var panadapter         : Panadapter?
  
    override func viewDidLoad() {
        super.viewDidLoad()

      
      
      // set the background color of the Flag
//      view.layer?.backgroundColor = NSColor.lightGray.cgColor
      
      tabViewItems[0].view?.layer?.backgroundColor = NSColor.lightGray.cgColor
    }
    

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameters:
  ///   - panadapter:               a Panadapter reference
  ///   - slice:                    a Slice reference
  ///
  func configure(panadapter: Panadapter?, slice: xLib6000.Slice?) {
    self.panadapter = panadapter
    self.slice = slice!

    tabViewItems[selectedTabViewItemIndex].viewController?.representedObject = slice
  }
}
