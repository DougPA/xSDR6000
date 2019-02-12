//
//  PCWPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/11/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

final class PCWPrefsViewController                : NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _micBiasCheckbox       : NSButton!
  @IBOutlet private weak var _metInRxCheckbox       : NSButton!
  @IBOutlet private weak var _micBoostCheckbox      : NSButton!
  @IBOutlet private weak var _iambicCheckbox        : NSButton!
  @IBOutlet private weak var _swapPaddlesCheckbox   : NSButton!
  @IBOutlet private weak var _cwxSyncCheckbox       : NSButton!
  @IBOutlet private weak var _cwLowerRadioButton    : NSButton!
  @IBOutlet private weak var _cwUpperRadioButton    : NSButton!
  @IBOutlet private weak var _iambicARadioButton    : NSButton!
  @IBOutlet private weak var _iambicBRadioButton    : NSButton!
  @IBOutlet private weak var _rttyMarkTextField     : NSTextField!
  
  private var _radio                        : Radio? { return Api.sharedInstance.radio }
  private var _transmit                     : Transmit? { return _radio!.transmit }
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // begin observing properties
    addObservations()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Iambic radio buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func micCheckBoxes(_ sender: NSButton) {

    switch sender.identifier?.rawValue {
    case "MicBias":
      _transmit!.micBiasEnabled = sender.boolState
    case "MicBoost":
      _transmit!.micBoostEnabled = sender.boolState
    case "MetInRx":
      _transmit!.metInRxEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  /// Respond to the Iambic radio buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func iambicMode(_ sender: NSButton) {
    
    switch sender.identifier?.rawValue {
    case "IambicA":
      _transmit!.cwIambicMode = 0
    case "IambicB":
      _transmit!.cwIambicMode = 1
    default:
      fatalError()
    }
  }
  /// Respond to the Cw radio buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func cwSideband(_ sender: NSButton) {
    
    switch sender.identifier?.rawValue {
    case "CwSidebandUpper":
      _transmit!.cwlEnabled = false
    case "CwSidebandLower":
      _transmit!.cwlEnabled = true
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
      _transmit!.observe(\.micBiasEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.metInRxEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.micBoostEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.cwIambicEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.cwIambicMode, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.cwlEnabled, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _transmit!.observe(\.cwSwapPaddles, options: [.initial, .new], changeHandler: transmitHandler(_:_:)),
      _radio!.observe(\.rttyMark, options: [.initial, .new], changeHandler: radioHandler(_:_:))
    ]
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - transmit:                 the Transmit being observed
  ///   - change:                   the change
  ///
  private func transmitHandler(_ transmit: Transmit, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._micBiasCheckbox.boolState = transmit.micBiasEnabled
      self?._metInRxCheckbox.boolState = transmit.metInRxEnabled
      self?._micBoostCheckbox.boolState = transmit.micBoostEnabled
      self?._iambicCheckbox.boolState = transmit.cwIambicEnabled
      self?._swapPaddlesCheckbox.boolState = transmit.cwSwapPaddles
      
      // Iambic A/B
      if self?._transmit!.cwIambicMode == 0 {
        // A Mode
        self?._iambicARadioButton.boolState = true
        
      } else {
        // B Mode
        self?._iambicBRadioButton.boolState = true
      }
      // CW Upper/Lower sideband
      if self?._transmit!.cwlEnabled ?? false {
        // Lower
        self?._cwLowerRadioButton.boolState = true
        
      } else {
        // Upper
        self?._cwUpperRadioButton.boolState = true
      }
    }
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - radio:                    the Radio being observed
  ///   - change:                   the change
  ///
  private func radioHandler(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._rttyMarkTextField.integerValue = radio.rttyMark
    }
  }
}
