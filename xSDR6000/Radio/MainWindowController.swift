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
  
  @IBOutlet weak var tnfsEnabled            : NSButton!
  @IBOutlet weak var markersEnabled         : NSButton!
  @IBOutlet weak var lineoutGain            : NSSlider!
  @IBOutlet weak var headphoneGain          : NSSlider!
  @IBOutlet weak var sideViewOpen           : NSButton!
  @IBOutlet weak var macAudioEnabled        : NSButton!
  @IBOutlet weak var voltageTempMonitor     : ParameterMonitor?
  @IBOutlet weak var lineoutMute            : NSButton!
  @IBOutlet weak var headphoneMute          : NSButton!
  @IBOutlet weak var fullDuplexEnabled      : NSButton!
  @IBOutlet weak var cwxEnabled             : NSButton!
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func awakeFromNib() {
    windowFrameAutosaveName = NSWindow.FrameAutosaveName(rawValue: "MainWindow")
  }
}
