//
//  XRitViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/19/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - XRit View Controller class implementation
// --------------------------------------------------------------------------------

class XRitViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _rit           : NSButton!
  @IBOutlet private var _ritZero            : NSButton!
  @IBOutlet private weak var _ritOffset     : NSTextField!
  @IBOutlet private weak var _ritStepper    : NSStepper!
  
  @IBOutlet private weak var _xit           : NSButton!
  @IBOutlet private weak var _xitZero       : NSButton!
  @IBOutlet private weak var _xitOffset     : NSTextField!
  @IBOutlet private weak var _xitStepper    : NSStepper!
  
  
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
  
  // **** BUTTONS ****
  
  @IBAction func rit( sender: NSButton) {
    _slice.ritEnabled = sender.boolState
  }
  @IBAction func ritZero( sender: NSButton) {
    _slice.ritOffset = 0
  }
  @IBAction func ritStepper( sender: NSStepper) {
    _slice.xitOffset += Int(sender.increment)
  }
  @IBAction func xit( sender: NSButton) {
    _slice.xitEnabled = sender.boolState
  }
  @IBAction func xitZero( sender: NSButton) {
    _slice.xitOffset = 0
  }
  @IBAction func xitStepper( sender: NSStepper) {
    _slice.xitOffset += Int(sender.increment)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.ritEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.xitEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      
      _slice.observe(\.ritOffset, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.xitOffset, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
    ]
  }
  private func changeHandler(_ object: Any, _ change: Any) {
    DispatchQueue.main.async {
      self._rit.state = self._slice.ritEnabled.state
      self._xit.state = self._slice.xitEnabled.state
      
      self._ritOffset.integerValue = self._slice.ritOffset
      self._xitOffset.integerValue = self._slice.xitOffset
    }
  }
}
