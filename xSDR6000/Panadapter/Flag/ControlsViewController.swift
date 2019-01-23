//
//  ControlsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/8/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Controls View Controller class implementation
// --------------------------------------------------------------------------------

final class ControlsViewController: NSTabViewController {

  static let kControlsHeight                : CGFloat = 90  
  static let kBackgroundColor               = NSColor.black.withAlphaComponent(0.3).cgColor

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _slice                   : xLib6000.Slice?

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods

  override func viewDidLoad() {
    super.viewDidLoad()

    view.translatesAutoresizingMaskIntoConstraints = false
    
    view.isHidden = true
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    
    // set the background color of the Flag
    view.layer?.backgroundColor = ControlsViewController.kBackgroundColor
  }
  ///
  /// - Parameters:
  ///   - tabView:                  the TabView
  ///   - tabViewItem:              the Item being selected
  ///
  override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
    
    // give it a reference to the Slice
    tabViewItem?.viewController?.representedObject = _slice
    
//    // set Background color of the TabViewItem view
//    tabViewItem?.view?.layer?.backgroundColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.9).cgColor
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameters:
  ///   - panadapter:               a Panadapter reference
  ///   - slice:                    a Slice reference
  ///
  func configure(slice: xLib6000.Slice?) {
//    self.panadapter = panadapter
    _slice = slice!
    
    tabViewItems[0].viewController!.representedObject = _slice
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the 0 button for Rit
  ///
  /// - Parameter sender:           a button
  ///
  @IBAction func zeroRit(_ sender: NSButton) {
    _slice?.ritOffset = 0
  }
  /// Respond to the 0 button for Xit
  ///
  /// - Parameter sender:           a button
  ///
  @IBAction func zeroXit(_ sender: NSButton) {
    _slice?.xitOffset = 0
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
}
