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

//public typealias Params = (radio: Radio, panadapter: Panadapter?, waterfall: Waterfall?)     // Radio & Panadapter references

class PanafallsViewController               : NSSplitViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = OSLog(subsystem: "net.k3tzr.xSDR6000", category: "PanafallsVC")
  private var _sb                           : NSStoryboard?
  
  private let kPanafallStoryboard           = NSStoryboard.Name(rawValue: "Panafall")
  private let kPanafallButtonIdentifier     = NSStoryboard.SceneIdentifier(rawValue: "Button")
  
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
    NC.makeObserver(self, with: #selector(panadapterHasBeenAdded(_:)), of: .panadapterHasBeenAdded, object: nil)
    
    // Waterfall initialized
    NC.makeObserver(self, with: #selector(waterfallHasBeenAdded(_:)), of: .waterfallHasBeenAdded, object: nil)
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
    if let panadapter = note.object as? Panadapter {

      // YES, log the event
//      Log.sharedInstance.msg("ID = \(panadapter.id.hex)", level: .info, function: #function, file: #file, line: #line)

      os_log("Panadapter added, ID = %{public}@", log: _log, type: .info, panadapter.id.hex)
    }
  }
  /// Process .waterfallHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func waterfallHasBeenAdded(_ note: Notification) {
    // a Waterfall model has been added to the Waterfalls collection and Initialized
    
    // does the Notification contain a Panadapter?
    if let waterfall = note.object as? Waterfall {
      
      // YES, log the event
//      Log.sharedInstance.msg("ID = \(waterfall.id.hex)", level: .info, function: #function, file: #file, line: #line)

      os_log("Waterfall added, ID = %{public}@", log: _log, type: .info, waterfall.id.hex)

      let panadapter = Api.sharedInstance.radio!.panadapters[waterfall.panadapterId]
      
      // create a Panafall Button View Controller
      let panafallButtonVc = _sb!.instantiateController(withIdentifier: kPanafallButtonIdentifier) as! PanafallButtonViewController
      
      // pass needed parameters
      panafallButtonVc.configure(panadapter: panadapter, waterfall: waterfall)
      
      // interact with the UI
      DispatchQueue.main.sync { [unowned self] in
        
        self.addSplitViewItem(NSSplitViewItem(viewController: panafallButtonVc))
      }
    }
  }
}
