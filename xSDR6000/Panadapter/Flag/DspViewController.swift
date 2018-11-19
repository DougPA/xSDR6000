//
//  DspViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/18/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Dsp View Controller class implementation
// --------------------------------------------------------------------------------

class DspViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _wnb           : NSButton!
  @IBOutlet private weak var _nb            : NSButton!
  @IBOutlet private weak var _nr            : NSButton!
  @IBOutlet private weak var _anf           : NSButton!
  
  @IBOutlet private weak var _wnbLevel      : NSSlider!
  @IBOutlet private weak var _nbLevel       : NSSlider!
  @IBOutlet private weak var _nrLevel       : NSSlider!
  @IBOutlet private weak var _anfLevel      : NSSlider!
  
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
  
  @IBAction func wnb( sender: NSButton) {
    _slice.wnbEnabled = sender.boolState
  }
  @IBAction func nb( sender: NSButton) {
    _slice.nbEnabled = sender.boolState
  }
  @IBAction func nr( sender: NSButton) {
    _slice.nrEnabled = sender.boolState
  }
  @IBAction func anf( sender: NSButton) {
    _slice.anfEnabled = sender.boolState
  }

  // **** SLIDERS ****

  @IBAction func wnbLevel(_ sender: NSSlider) {
    _slice.wnbLevel = sender.integerValue
  }
  @IBAction func wbLevel(_ sender: NSSlider) {
    _slice.nbLevel = sender.integerValue
  }
  @IBAction func nrLevel(_ sender: NSSlider) {
    _slice.nrLevel = sender.integerValue
  }
  @IBAction func anfLevel(_ sender: NSSlider) {    
    _slice.anfLevel = sender.integerValue
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.wnbEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.nbEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.nrEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.anfEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),

      _slice.observe(\.wnbLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.nbLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.nrLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.anfLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  private func changeHandler(_ object: Any, _ change: Any) {
    DispatchQueue.main.async {
      self._wnb.state = self._slice.wnbEnabled.state
      self._nb.state = self._slice.nbEnabled.state
      self._nr.state = self._slice.nrEnabled.state
      self._anf.state = self._slice.anfEnabled.state

      self._wnbLevel.integerValue = self._slice.wnbLevel
      self._nbLevel.integerValue = self._slice.nbLevel
      self._nrLevel.integerValue = self._slice.nrLevel
      self._anfLevel.integerValue = self._slice.anfLevel
    }
  }
}
