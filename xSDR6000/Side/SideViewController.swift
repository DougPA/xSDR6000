//
//  SideViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Side View Controller class implementation
// --------------------------------------------------------------------------------

final class SideViewController              : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _scrollView    : NSScrollView!
  @IBOutlet private weak var _insideView    : NSView!
  
  
  @IBOutlet private weak var _container1HeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var _container2HeightConstraint: NSLayoutConstraint!
  
  private var _api                          = Api.sharedInstance

  private var _topConstraints               = [NSLayoutConstraint]()

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.translatesAutoresizingMaskIntoConstraints = false

    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    addNotifications()
    
    let widthConstraint = view.widthAnchor.constraint(equalToConstant: 311)
    widthConstraint.identifier = "Side width constraint"
    widthConstraint.isActive = true
  }

  override func viewDidAppear() {
    
    // position the scroll view at the top
    if let docView = _scrollView.documentView {
      docView.scroll(NSPoint(x: 0, y: docView.bounds.size.height))
    }

  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the Side buttons
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func sideButtons(_ sender: NSButton) {
    
    switch sender.identifier?.rawValue ?? "" {
    case "RX":
      break
    case "TX":
      break
    case "PCW":
      break
    case "PHNE":
      _container1HeightConstraint.constant = (sender.boolState ? 210 : 0)
    case "EQ":
      _container2HeightConstraint.constant = (sender.boolState ? 210 : 0)
    default:
      fatalError()
    }
    // position the scroll view at the top
    if let docView = _scrollView.documentView {
      docView.scroll(NSPoint(x: 0, y: docView.bounds.size.height))
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(frameDidChange(_:)), of: NSView.frameDidChangeNotification.rawValue, object: view)
  }
  /// Process frameDidChange Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func frameDidChange(_ note: Notification) {
    
    // position the scroll view at the top
    if let docView = _scrollView.documentView {
      docView.scroll(NSPoint(x: 0, y: docView.bounds.size.height))
    }
  }
}
