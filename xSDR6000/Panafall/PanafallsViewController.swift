//
//  PanafallsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

//public typealias Params = (radio: Radio, panadapter: Panadapter?, waterfall: Waterfall?)     // Radio & Panadapter references

class PanafallsViewController               : NSSplitViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // constants
  private let kPanafallStoryboard           = "Panafall"                    // Storyboard names
  
  private let kPanafallButtonIdentifier     = "Button"                      // Storyboard identifiers
  private let kPanadapterIdentifier         = "Panadapter"
  private let kWaterfallIdentifier          = "Waterfall"
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
      Log.sharedInstance.msg("ID = \(panadapter.id.hex)", level: .debug, function: #function, file: #file, line: #line)
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
      Log.sharedInstance.msg("ID = \(waterfall.id.hex)", level: .debug, function: #function, file: #file, line: #line)
      
      let panadapter = Api.sharedInstance.radio!.panadapters[waterfall.panadapterId]
      
      // get the Storyboard containing a Panafall Button View Controller
      let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: self.kPanafallStoryboard), bundle: nil)
      
      // create a Panafall Button View Controller
      let panafallButtonVc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: self.kPanafallButtonIdentifier)) as! PanafallButtonViewController
      
      panafallButtonVc.panadapter = panadapter
      
      // interact with the UI
      DispatchQueue.main.sync { [unowned self] in
        
        self.addSplitViewItem(NSSplitViewItem(viewController: panafallButtonVc))
      }
    }
  }
}
