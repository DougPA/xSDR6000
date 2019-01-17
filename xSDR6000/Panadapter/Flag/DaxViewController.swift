//
//  DaxViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/7/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class DaxViewController: NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _daxPopUp      : NSPopUpButton!
  
  private var _slice                        : xLib6000.Slice {
    return representedObject as! xLib6000.Slice }
  
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor

    // populate the choices
    _daxPopUp.addItems(withTitles: Api.daxChannels)
    
    // start observing
    addObservations()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the DAX popup
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func buttons(_ sender: NSPopUpButton) {
    
    _slice.daxChannel = sender.indexOfSelectedItem
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.daxChannel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
    ]
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the slice being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ slice: xLib6000.Slice, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._daxPopUp.selectItem(at: slice.daxChannel)
    }
  }
}