//
//  AudioViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 11/18/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Audio View Controller class implementation
// --------------------------------------------------------------------------------

class AudioViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _audioGain     : NSSlider!
  @IBOutlet private weak var _audioPan      : NSSlider!
  @IBOutlet private weak var _agcThreshold  : NSSlider!
  @IBOutlet private weak var _muteButton    : NSButton!
  @IBOutlet private weak var _agcPopUp      : NSPopUpButton!
  
  private var _slice                        : xLib6000.Slice {
    return representedObject as! xLib6000.Slice }

  private var _observations                 : [NSKeyValueObservation]?

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    if _observations == nil {
      _observations = [NSKeyValueObservation]()
      
      _agcPopUp.addItems(withTitles: _slice.agcNames)
      
      addObservations()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  // **** BUTTONS ****
  
  @IBAction func audioMute(_ sender: NSButton) {
    _slice.audioMute = sender.boolState
  }
  
  // **** POPUPS ****
  
  @IBAction func agcMode(_ sender: NSPopUpButton) {
    _slice.agcMode = sender.titleOfSelectedItem!
  }

  // **** SLIDERS ****
  
  @IBAction func audioGain(_ sender: NSSlider) {
    _slice.audioGain = sender.integerValue
  }
  @IBAction func audioPan(_ sender: NSSlider) {
    _slice.audioPan = sender.integerValue
  }
  @IBAction func agcThreshold(_ sender: NSSlider) {
    _slice.agcThreshold = sender.integerValue
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods  
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.audioMute, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.audioGain, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.audioPan, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.agcThreshold, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.agcMode, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  private func changeHandler(_ object: Any, _ change: Any) {
    DispatchQueue.main.async {
      self._muteButton.state = self._slice.audioMute.state
      self._audioGain.integerValue = self._slice.audioGain
      self._audioPan.integerValue = self._slice.audioPan
      self._agcThreshold.integerValue = self._slice.agcThreshold
      self._agcPopUp.selectItem(withTitle: self._slice.agcMode)
    }
  }
}
