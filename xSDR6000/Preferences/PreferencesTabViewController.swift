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
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor
    
    Swift.print("Loaded tabId \(Defaults[.preferencesTabId])")

    tabView.selectTabViewItem(withIdentifier: NSUserInterfaceItemIdentifier(Defaults[.preferencesTabId]) )
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.window!.setFrameUsingName(_autosaveName)
    
    // select the previously displayed tab
    tabView.selectTabViewItem(withIdentifier: NSUserInterfaceItemIdentifier(Defaults[.preferencesTabId]) )
  }
  
  override func viewWillDisappear() {
    super.viewWillDisappear()
    
    view.window!.saveFrame(usingName: _autosaveName)

    // close the ColorPicker (if open)
    if NSColorPanel.shared.isVisible {
      NSColorPanel.shared.performClose(nil)
    }
    // save the currently displayed tab
    Defaults[.preferencesTabId] = (tabView.selectedTabViewItem?.identifier as! NSUserInterfaceItemIdentifier).rawValue
  }

  override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
    super.tabView(tabView, willSelect: tabViewItem)

    let id = (tabViewItem!.identifier as! NSUserInterfaceItemIdentifier).rawValue
    // give the newly selected tab a reference to an object (if needed)
    switch id {
    case "Colors", "Info":
      tabViewItem?.viewController?.representedObject = Defaults
    default:
      break
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
}

