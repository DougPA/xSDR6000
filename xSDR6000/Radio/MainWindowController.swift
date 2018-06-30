//
//  MainWindowController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 3/1/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class MainWindowController                  : NSWindowController {
  
  @objc dynamic var api                     = Api.sharedInstance
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @IBOutlet weak var voltageTempMonitor     : ParameterMonitor?
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func awakeFromNib() {
    windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: "MainWindow")
  }
}
