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
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @IBOutlet weak var lineoutGain            : NSSlider!
  @IBOutlet weak var lineoutMute            : NSButton!
  
  @IBOutlet weak var headphoneGain          : NSSlider!
  @IBOutlet weak var headphoneMute          : NSButton!
  
  @IBOutlet weak var tnfEnabled             : NSButton!
  @IBOutlet weak var sideEnabled            : NSButton!
  @IBOutlet weak var remoteRxEnabled        : NSButton!
  @IBOutlet weak var remoteTxEnabled        : NSButton!
  @IBOutlet weak var cwxEnabled             : NSButton!
  @IBOutlet weak var fdxEnabled             : NSButton!
  
  @IBOutlet weak var voltageTempMonitor     : ParameterMonitor?
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func awakeFromNib() {
    windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: "MainWindow")
  }
}
