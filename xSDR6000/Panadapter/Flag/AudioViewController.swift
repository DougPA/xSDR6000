//
//  AudioViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/7/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class AudioViewController: NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  @IBOutlet private weak var _audioMuteButton     : NSButton!
  @IBOutlet private weak var _agcModePopUp        : NSPopUpButton!
  @IBOutlet private weak var _audioGainSlider     : NSSlider!
  @IBOutlet private weak var _audioPanSlider      : NSSlider!
  @IBOutlet private weak var _agcThresholdSlider  : NSSlider!

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
    _agcModePopUp.addItems(withTitles: Slice.AgcMode.allCases.map {$0.rawValue} )
//    _agcModePopUp.selectItem(withTitle: _slice.agcMode)

    // start observing
    addObservations()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Mute button
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func audioMuteButton(_ sender: NSButton) {

    _slice.audioMute = sender.boolState
  }
  /// Respond to the AGC Mode popup
  ///
  /// - Parameter sender:         the popup
  ///
  @IBAction func agcModeButton(_ sender: NSPopUpButton) {
  
    _slice.mode = sender.titleOfSelectedItem!
  }
 /// Respond to one of the sliders
  ///
  /// - Parameter sender:         the slider
  ///
  @IBAction func sliders(_ sender: NSSlider) {
    
    switch sender.identifier!.rawValue {
    case "audioGain":
      _slice.audioGain = sender.integerValue
    case "audioPan":
      _slice.audioPan = sender.integerValue
    case "agcThreshold":
      _slice.agcThreshold = sender.integerValue
    default:
      fatalError()
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.audioGain, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.audioPan, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.agcThreshold, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.audioMute, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.agcMode, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
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
      self?._audioMuteButton.boolState = slice.audioMute
      
      self?._audioGainSlider.integerValue = slice.audioGain
      self?._audioPanSlider.integerValue = slice.audioPan
      self?._agcThresholdSlider.integerValue = slice.agcThreshold
      
      self?._agcModePopUp.selectItem(withTitle: slice.agcMode)
    }
  }
}
