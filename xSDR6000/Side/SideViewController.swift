//
//  SideViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults

// --------------------------------------------------------------------------------
// MARK: - Side View Controller class implementation
// --------------------------------------------------------------------------------

final class SideViewController              : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _scrollView    : NSScrollView!
  @IBOutlet private weak var _insideView    : NSView!
  @IBOutlet private weak var _clipView      : NSClipView!
  
  @IBOutlet private weak var _rxButton      : NSButton!
  @IBOutlet private weak var _txButton      : NSButton!
  @IBOutlet private weak var _pcwButton     : NSButton!
  @IBOutlet private weak var _phneButton    : NSButton!
  @IBOutlet private weak var _eqButton      : NSButton!
  
  
  @IBOutlet private weak var _insideViewHeight      : NSLayoutConstraint!
  @IBOutlet private weak var _rxContainerHeight     : NSLayoutConstraint!
  @IBOutlet private weak var _txContainerHeight     : NSLayoutConstraint!
  @IBOutlet private weak var _pcwContainerHeight    : NSLayoutConstraint!
  @IBOutlet private weak var _phneContainerHeight   : NSLayoutConstraint!
  @IBOutlet private weak var _eqContainerHeight     : NSLayoutConstraint!
  
  
  private var _api                          = Api.sharedInstance

  private var _topConstraints               = [NSLayoutConstraint]()
  
  private let kStateOn                      = NSControl.StateValue.on
  private let kStateOff                     = NSControl.StateValue.off
  private let kHeightOpen                   : CGFloat = 210
  private let kHeightClosed                 : CGFloat = 0

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
    
    // set the button states
    _rxButton.state = Defaults[.sideRxOpen].state
    _txButton.state = Defaults[.sideTxOpen].state
    _pcwButton.state = Defaults[.sidePcwOpen].state
    _phneButton.state = Defaults[.sidePhneOpen].state
    _eqButton.state = Defaults[.sideEqOpen].state
    
    // unhide the selected views
    _rxContainerHeight.constant = ( Defaults[.sideRxOpen] ? kHeightOpen : kHeightClosed )
    _txContainerHeight.constant = ( Defaults[.sideTxOpen] ? kHeightOpen : kHeightClosed )
    _pcwContainerHeight.constant = ( Defaults[.sidePcwOpen] ? kHeightOpen : kHeightClosed )
    _phneContainerHeight.constant = ( Defaults[.sidePhneOpen] ? kHeightOpen : kHeightClosed )
    _eqContainerHeight.constant = ( Defaults[.sideEqOpen] ? kHeightOpen : kHeightClosed )

    _scrollView.needsLayout = true
//    positionAtTop(_scrollView)
  }

//  override func viewDidAppear() {
//
//    // position the scroll view at the top
//    positionAtTop(_clipView)
//  }
  
  override func viewDidLayout() {

    // position the scroll view at the top
    positionAtTop(_scrollView)
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
      Defaults[.sideRxOpen] = sender.boolState
      _rxContainerHeight.constant = (sender.boolState ? 210 : 0)
    case "TX":
      Defaults[.sideTxOpen] = sender.boolState
      _txContainerHeight.constant = (sender.boolState ? 210 : 0)
    case "PCW":
      Defaults[.sidePcwOpen] = sender.boolState
      _pcwContainerHeight.constant = (sender.boolState ? 210 : 0)
    case "PHNE":
      Defaults[.sidePhneOpen] = sender.boolState
      _phneContainerHeight.constant = (sender.boolState ? 210 : 0)
    case "EQ":
      Defaults[.sideEqOpen] = sender.boolState
      _eqContainerHeight.constant = (sender.boolState ? 210 : 0)
    default:
      fatalError()
    }
    _scrollView.needsLayout = true
    
//    // position the scroll view at the top
//    positionAtTop(_scrollView)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func positionAtTop(_ scrollView: NSScrollView) {
    
    Swift.print("scrollViewHeight = \(scrollView.frame.height), docViewHeight = \(scrollView.documentView!.frame.height)")
    
//    _insideViewHeight.constant = max(1050, view.frame.height)

    // position the scroll view at the top
    if let docView = scrollView.documentView {
      docView.scroll(NSPoint(x: 0, y: view.frame.height))
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
//    positionAtTop(_scrollView)
    _scrollView.needsLayout = true
  }
}
