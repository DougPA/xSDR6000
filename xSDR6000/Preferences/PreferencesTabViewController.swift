//
//  PreferencesTabViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/16/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

// ----------------------------------------------------------------------------
// MARK: - Overrides

final class PreferencesTabViewController    : NSTabViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _autosaveName                 = "PreferencesWindow"
  
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
    
    // give the newly selected tab a reference to the User Defaults
    tabViewItem?.viewController?.representedObject = Defaults
  }
  
}
