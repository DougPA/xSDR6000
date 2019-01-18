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

  @IBOutlet private weak var _rxContainer   : NSView!
  
  @IBOutlet private weak var _scrollView    : NSScrollView!
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
  
  private var _rxViewLoaded                 = false
  private var _flagVc                       : FlagViewController?
  private var _observations                 = [NSKeyValueObservation]()
  
  private let kSideViewWidth                : CGFloat = 311
  private let kRxHeightOpen                 : CGFloat = 100
  private let kTxHeightOpen                 : CGFloat = 210
  private let kPcwHeightOpen                : CGFloat = 240
  private let kPhneHeightOpen               : CGFloat = 210
  private let kEqHeightOpen                 : CGFloat = 210
  private let kHeightClosed                 : CGFloat = 0

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.black.cgColor
    
    addNotifications()
    
    let widthConstraint = view.widthAnchor.constraint(equalToConstant: kSideViewWidth)
    widthConstraint.identifier = "Side width constraint"
    widthConstraint.isActive = true

    // set the button states
    _rxButton.state = Defaults[.sideRxOpen].state
    _txButton.state = Defaults[.sideTxOpen].state
    _pcwButton.state = Defaults[.sidePcwOpen].state
    _phneButton.state = Defaults[.sidePhneOpen].state
    _eqButton.state = Defaults[.sideEqOpen].state
    
    // unhide the selected views
    _rxContainerHeight.constant = ( Defaults[.sideRxOpen] ? kRxHeightOpen : kHeightClosed )
    _txContainerHeight.constant = ( Defaults[.sideTxOpen] ? kTxHeightOpen : kHeightClosed )
    _pcwContainerHeight.constant = ( Defaults[.sidePcwOpen] ? kPcwHeightOpen : kHeightClosed )
    _phneContainerHeight.constant = ( Defaults[.sidePhneOpen] ? kPhneHeightOpen : kHeightClosed )
    _eqContainerHeight.constant = ( Defaults[.sideEqOpen] ? kEqHeightOpen : kHeightClosed )

    _scrollView.needsLayout = true
  }
//  override func viewWillAppear() {
//    super.viewWillAppear()
//
//    if Defaults[.sideRxOpen] && !_rxViewLoaded { initialFlagLoad() }
//  }
  override func viewDidLayout() {

    // position the scroll view at the top
    positionAtTop(_scrollView)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the Side buttons
  ///
  /// - Parameter sender:             the Button
  ///
  @IBAction func sideButtons(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "RX":
      Defaults[.sideRxOpen] = sender.boolState
      _rxContainerHeight.constant = (sender.boolState ? kRxHeightOpen : kHeightClosed)
    case "TX":
      Defaults[.sideTxOpen] = sender.boolState
      _txContainerHeight.constant = (sender.boolState ? kTxHeightOpen : kHeightClosed)
    case "PCW":
      Defaults[.sidePcwOpen] = sender.boolState
      _pcwContainerHeight.constant = (sender.boolState ? kPcwHeightOpen : kHeightClosed)
    case "PHNE":
      Defaults[.sidePhneOpen] = sender.boolState
      _phneContainerHeight.constant = (sender.boolState ? kPhneHeightOpen : kHeightClosed)
    case "EQ":
      Defaults[.sideEqOpen] = sender.boolState
      _eqContainerHeight.constant = (sender.boolState ? kEqHeightOpen : kHeightClosed)
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
 
  func setRxHeight(_ height: CGFloat) {
    self._rxContainerHeight.constant = height
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func loadFlag(slice: xLib6000.Slice, panadapter: Panadapter) {
    
    // get the Storyboard containing a Flag View Controller
    let sb = NSStoryboard(name: "Flag", bundle: nil)
    
    // create a Flag View Controller & pass it needed parameters
    _flagVc = sb.instantiateController(withIdentifier: "Flag") as? FlagViewController
    
    // create a Controls View Controller & pass it needed parameters
    let controlsVc = sb.instantiateController(withIdentifier: "Controls") as! ControlsViewController
    
    // pass the FlagVc needed parameters
    _flagVc!.configure(panadapter: panadapter, slice: slice, controlsVc: controlsVc, vc: self)
    _flagVc!.smallFlagDisplayed = false
    _flagVc!.isOnLeft = true

    // add the views
    self._rxContainer.addSubview(self._flagVc!.view)
    self._rxContainer.addSubview(self._flagVc!.controlsVc!.view)

    // Flag View constraints: height, width & top of the Flag (constants)
    self._flagVc!.flagHeightConstraint = self._flagVc!.view.heightAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagHeight)
    self._flagVc!.flagWidthConstraint = self._flagVc!.view.widthAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagWidth)
    let top = self._flagVc!.view.topAnchor.constraint(equalTo: self._rxContainer.topAnchor)
    
    // Flag View constraints: position (will be changed as Flag moves)
    self._flagVc!.flagXPositionConstraint = self._flagVc!.view.leadingAnchor.constraint(equalTo: self._rxContainer.leadingAnchor, constant: 0)
    
    // activate Flag constraints
    let constraints = [self._flagVc!.flagHeightConstraint!, self._flagVc!.flagWidthConstraint!, self._flagVc!.flagXPositionConstraint!, top]
    NSLayoutConstraint.activate(constraints)
    
    // Controls View constraints: height, leading, trailing & top of the Controls (constants)
    self._flagVc!.controlsHeightConstraint = self._flagVc!.controlsVc!.view.heightAnchor.constraint(equalToConstant: ControlsViewController.kControlsHeight)
    let leadingConstraint = self._flagVc!.controlsVc!.view.leadingAnchor.constraint(equalTo: self._flagVc!.view.leadingAnchor)
    let trailingConstraint = self._flagVc!.controlsVc!.view.trailingAnchor.constraint(equalTo: self._flagVc!.view.trailingAnchor)
    let topConstraint = self._flagVc!.controlsVc!.view.topAnchor.constraint(equalTo: self._flagVc!.view.bottomAnchor)
    let heightConstraint = self._flagVc!.controlsVc!.view.heightAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagHeight)
    let widthConstraint = self._flagVc!.controlsVc!.view.widthAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagWidth)
    
    // activate Controls constraints
    let controlsConstraints: [NSLayoutConstraint] = [self._flagVc!.controlsHeightConstraint!, leadingConstraint, trailingConstraint, topConstraint, heightConstraint, widthConstraint]
    NSLayoutConstraint.activate(controlsConstraints)
    
    self._rxContainerHeight.constant = (self._flagVc!.controlsVc!.view.isHidden ? 100 : 200)
  }
  /// Position a scroll view at the top
  ///
  /// - Parameter scrollView:         the ScrollView
  ///
  private func positionAtTop(_ scrollView: NSScrollView) {
    
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
    NC.makeObserver(self, with: #selector(activeSliceChange(_:)), of: .sliceHasBeenAdded)
    NC.makeObserver(self, with: #selector(activeSliceChange(_:)), of: .sliceBecameActive)
  }
  /// Process frameDidChange Notification
  ///
  /// - Parameter note:               a Notification instance
  ///
  @objc private func frameDidChange(_ note: Notification) {
    
    _scrollView.needsLayout = true
  }
  /// Process .sliceHasBeenAdded & .sliceBecameActiv Notification
  ///
  /// - Parameter note:               a Notification instance
  ///
  @objc private func activeSliceChange(_ note: Notification) {
    
    let slice = note.object as! xLib6000.Slice

    // find the Panadapter of the Slice
    let pan = Api.sharedInstance.radio!.panadapters[slice.panadapterId]!
    
    // has the Rx Side view been loaded?
    if _rxViewLoaded  {
      // YES, update it
      DispatchQueue.main.async {
        
        self._flagVc!.updateFlag(slice: slice, panadapter: pan)
      }

    } else {
      // NO, load it
      _rxViewLoaded = true
      DispatchQueue.main.async {

        self.loadFlag(slice: slice, panadapter: pan)
      }
    }
  }
}
