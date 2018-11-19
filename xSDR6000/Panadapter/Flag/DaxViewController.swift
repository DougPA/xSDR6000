//
//  DaxViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/19/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Dax View Controller class implementation
// --------------------------------------------------------------------------------

class DaxViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _daxPopup      : NSPopUpButton!
  
  private var _slice                        : xLib6000.Slice {
    return representedObject as! xLib6000.Slice }
  
  private var _observations                 : [NSKeyValueObservation]?
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    if _observations == nil {
      _observations = [NSKeyValueObservation]()
      
      addObservations()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods

  @IBAction func daxPopup(_ sender: NSPopUpButton) {
    _slice.daxChannel = sender.indexOfSelectedItem
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.daxChannel, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  private func changeHandler(_ object: Any, _ change: Any) {
    DispatchQueue.main.async {
      self._daxPopup.selectItem(at: self._slice.daxChannel)
    }
  }

}
