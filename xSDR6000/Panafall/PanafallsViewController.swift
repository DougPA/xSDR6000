//
//  PanafallsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import os.log
import xLib6000

// --------------------------------------------------------------------------------
//  Created by RadioViewController
//  Removed by Application termination
//
//  **** Notifications received ****
//      .panadapterHasBeenAdded -> log only
//      .waterfallHasBeenAdded -> create Panafall view hierarchy
//
//  **** Action Methods ****
//      None
//
//  **** Observations ****
//      None
//
//  **** View Bindings ****
//      None
//
// --------------------------------------------------------------------------------

class PanafallsViewController               : NSSplitViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "PanafallsVC")
  private var _sb                           : NSStoryboard?
  
  private let kPanafallStoryboard           = "Panafall"
  private let kPanafallButtonIdentifier     = "Button"
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // get the Storyboard containing a Panafall Button View Controller
    _sb = NSStoryboard(name: kPanafallStoryboard, bundle: nil)

    // add notification subscriptions
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    // Panadapter initialized
    NC.makeObserver(self, with: #selector(panadapterHasBeenAdded(_:)), of: .panadapterHasBeenAdded)
    
    // Waterfall initialized
    NC.makeObserver(self, with: #selector(waterfallHasBeenAdded(_:)), of: .waterfallHasBeenAdded)
  }
  //
  //  Panafall creation:
  //
  //      Step 1 .panadapterInitialized
  //      Step 2 .waterfallInitialized
  //
  /// Process .panadapterHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func panadapterHasBeenAdded(_ note: Notification) {
    // a Panadapter model has been added to the Panadapters collection and Initialized

    // does the Notification contain a Panadapter?
    let panadapter = note.object as! Panadapter
    
    // YES, log the event
    os_log("Panadapter added: ID = %{public}@", log: _log, type: .info, panadapter.id.hex)
  }
  /// Process .waterfallHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func waterfallHasBeenAdded(_ note: Notification) {
    // a Waterfall model has been added to the Waterfalls collection and Initialized
    
    // does the Notification contain a Panadapter?
    let waterfall = note.object as! Waterfall
    
    // YES, log the event
    os_log("Waterfall added: ID = %{public}@", log: _log, type: .info, waterfall.id.hex)
    
    let panadapter = Api.sharedInstance.radio!.panadapters[waterfall.panadapterId]
    
    // create a Panafall Button View Controller
    let panafallButtonVc = _sb!.instantiateController(withIdentifier: kPanafallButtonIdentifier) as! PanafallButtonViewController
    
    // interact with the UI
    DispatchQueue.main.sync { [unowned self] in
      
      // pass needed parameters
      panafallButtonVc.configure(panadapter: panadapter, waterfall: waterfall)
    
      self.addSplitViewItem(NSSplitViewItem(viewController: panafallButtonVc))
    }
  }
}
