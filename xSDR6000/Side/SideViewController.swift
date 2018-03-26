//
//  SideViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa

// --------------------------------------------------------------------------------
// MARK: - Side View Controller class implementation
// --------------------------------------------------------------------------------

final class SideViewController              : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var defaultWidth                          : CGFloat = 187
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet weak var sideWidthConstraint    : NSLayoutConstraint!
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func state( _ value: Bool) {
    sideWidthConstraint.constant = (value) ? defaultWidth : 0
  }
}
