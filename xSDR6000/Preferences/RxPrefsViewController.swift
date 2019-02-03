//
//  RxPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/13/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

final class RxPrefsViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _calibrateButton: NSButton!
  @IBOutlet private weak var _calFreqTextField        : NSTextField!
  @IBOutlet private weak var _calOffsetTextField      : NSTextField!  
  @IBOutlet private weak var _snapTuneCheckbox        : NSButton!
  @IBOutlet private weak var _singleClickCheckbox     : NSButton!
  @IBOutlet private weak var _startSliceMinCheckbox   : NSButton!
  @IBOutlet private weak var _muteLocalAudioCheckbox  : NSButton!
  @IBOutlet private weak var _binauralAudioCheckbox   : NSButton!
  
  private var _radio                        : Radio? { return Api.sharedInstance.radio }
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden  methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
//    // check for an active radio
//    if let radio = Api.sharedInstance.radio{ _radio = radio ; setControlStatus(true) }
//
//    // start receiving notifications
//    addNotifications()
    addObservations()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action  methods
  
  @IBAction func calibrate(_ sender: NSButton) {

    _radio?.startCalibration = true
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable controls
  ///
  /// - Parameter status:             true = enable
  ///
//  private func setControlStatus(_ status: Bool) {
//
//    if status {
//      addObservations()
//    } else {
//      removeObservations()
//    }
//    DispatchQueue.main.async { [weak self] in
//      self?._calibrateButton.isEnabled = status
//      self?._calFreqTextField.isEnabled = status
//      self?._calOffsetTextField.isEnabled = status
//      self?._snapTuneCheckbox.isEnabled = status
//      //    self?._singleClickCheckbox.isEnabled = status
//      //    self?._startSliceMinCheckbox.isEnabled = status
//      self?._muteLocalAudioCheckbox.isEnabled = status
//      self?._binauralAudioCheckbox.isEnabled = status
//    }
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _radio!.observe(\.calFreq, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.freqErrorPpb, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.snapTuneEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.muteLocalAudio, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.binauralRxEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  /// Remove observations
  ///
//  func removeObservations() {
//
//    // invalidate each observation
//    _observations.forEach { $0.invalidate() }
//
//    // remove the tokens
//    _observations.removeAll()
//  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the panadapter being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ radio: Radio, _ change: Any) {

    DispatchQueue.main.async { [weak self] in
      self?._calFreqTextField.integerValue = radio.calFreq
      self?._calOffsetTextField.integerValue = radio.freqErrorPpb
      self?._snapTuneCheckbox.boolState = radio.snapTuneEnabled
      self?._muteLocalAudioCheckbox.boolState = radio.muteLocalAudio
      self?._binauralAudioCheckbox.boolState = radio.binauralRxEnabled
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
//  private func addNotifications() {
//
//    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded)
//
//    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved)
//  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
//  @objc private func radioHasBeenAdded(_ note: Notification) {
//
//    if let radio = note.object as? Radio {
//
//      _radio = radio
//
//      // enable all controls
//      setControlStatus(true)
//    }
//  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
//  @objc private func radioWillBeRemoved(_ note: Notification) {
//
//    // disable all controls
//    setControlStatus(false)
//
//    _radio = nil
//  }
}
