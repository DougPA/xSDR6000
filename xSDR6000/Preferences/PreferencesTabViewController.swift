//
//  PreferencesTabViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/16/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import os.log
import xLib6000
import SwiftyUserDefaults

// ----------------------------------------------------------------------------
// MARK: - Overrides

final class PreferencesTabViewController    : NSTabViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _autosaveName                 = "PreferencesWindow"
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "Preferences")

//  private let kRadio                       = NSUserInterfaceItemIdentifier(rawValue: "Radio")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.window!.setFrameUsingName(_autosaveName)
  }
  
  override func viewWillDisappear() {
    super.viewWillDisappear()
    
    view.window!.saveFrame(usingName: _autosaveName)

    // close the ColorPicker (if open)
    if NSColorPanel.shared.isVisible {
      NSColorPanel.shared.performClose(nil)
    }
  }

//  override func tabView(_ tabView: NSTabView, shouldSelect: NSTabViewItem?) -> Bool {
//
//    guard Api.sharedInstance.radio != nil else {
//      return false
//    }
//    return true
//  }
  
  override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
    super.tabView(tabView, didSelect: tabViewItem)

    // give the newly selected tab a reference to an object
    switch (tabViewItem!.identifier as! NSUserInterfaceItemIdentifier).rawValue {
    case "Radio", "Network", "Gps", "Tx", "Rx", "Filters", "Xvtr":
      tabViewItem?.viewController?.representedObject = Api.sharedInstance.radio
    case "Phone/Cw", "Colors", "Info":
      tabViewItem?.viewController?.representedObject = Defaults
    default:
      fatalError()
    }
    // close the ColorPicker (if open)
    if NSColorPanel.shared.isVisible {
      NSColorPanel.shared.performClose(nil)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Quit menu item
  ///
  /// - Parameter sender:     the button
  ///
  @IBAction func quitRadio(_ sender: AnyObject) {
    
    dismiss(sender)
    
    // perform an orderly shutdown of all the components
    Api.sharedInstance.shutdown(reason: .normal)
    
    DispatchQueue.main.async {
      os_log("Application closed by user", log: self._log, type: .info)
      
      NSApp.terminate(self)
    }
  }

  // Rx Tab
  
  @IBAction func rxTabStart(_ sender: NSButton) {
    
    if let radio = Api.sharedInstance.radio {
      os_log("Calibration started by user", log: self._log, type: .info)
      radio.startCalibration = true
    }
  }
}

