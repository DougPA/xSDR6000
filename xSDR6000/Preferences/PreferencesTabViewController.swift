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

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // make me the delegate of the Tab View
    //        tabView.delegate = self
    
    // give the initially selected tab a reference to the User Defaults
    tabView.selectedTabViewItem?.viewController?.representedObject = Defaults
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.window!.setFrameUsingName(_autosaveName)
  }
  
  override func viewWillDisappear() {
    super.viewWillDisappear()
    
    view.window!.saveFrame(usingName: _autosaveName)
  }

  override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
    super.tabView(tabView, didSelect: tabViewItem)
    
    // give the newly selected tab a reference to an object
    switch tabViewItem!.label{
    case "Radio":
      break
    case "Network":
      break
    case "GPS":
      break
    case "TX":
      break
    case "Phone/CW":
      tabViewItem?.viewController?.representedObject = Defaults
    case "RX":
      break
    case "Filters":
      tabViewItem?.viewController?.representedObject = Api.sharedInstance.radio
    case "XVTR":
      break
    case "Colors":
      tabViewItem?.viewController?.representedObject = Defaults
    case "Info":
      tabViewItem?.viewController?.representedObject = Defaults
    default:
      fatalError()
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
  
  
  
  
}
