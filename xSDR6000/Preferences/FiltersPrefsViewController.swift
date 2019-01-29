//
//  FiltersPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/20/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class FiltersPrefsViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _voiceSlider         : NSSlider!
  @IBOutlet private weak var _cwSlider            : NSSlider!
  @IBOutlet private weak var _digitalSlider       : NSSlider!
  @IBOutlet private weak var _voiceAutoCheckbox   : NSButton!
  @IBOutlet private weak var _cwAutoCheckbox      : NSButton!
  @IBOutlet private weak var _digitalAutoCheckbox : NSButton!
  
  private var _radio                        : Radio?
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // check for an active radio
    if let radio = Api.sharedInstance.radio { _radio = radio ; setControlStatus(true) }
    
    // start receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable controls
  ///
  /// - Parameter status:             true = enable
  ///
  private func setControlStatus(_ status: Bool) {
    
    if status {
      addObservations()
    } else {
      removeObservations()
    }
    DispatchQueue.main.async { [weak self] in
      self?._voiceSlider.isEnabled = status
      self?._cwSlider.isEnabled = status
      self?._digitalSlider.isEnabled = status
      self?._voiceAutoCheckbox.isEnabled = status
      self?._cwAutoCheckbox.isEnabled = status
      self?._digitalAutoCheckbox.isEnabled = status
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _radio!.observe(\.filterVoiceLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.filterCwLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.filterDigitalLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.filterVoiceAutoEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.filterCwAutoEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _radio!.observe(\.filterDigitalAutoEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  /// Remove observations
  ///
  func removeObservations() {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // remove the tokens
    _observations.removeAll()
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the panadapter being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._voiceSlider.integerValue = radio.filterVoiceLevel
      self?._cwSlider.integerValue = radio.filterCwLevel
      self?._digitalSlider.integerValue = radio.filterDigitalLevel
      self?._voiceAutoCheckbox.boolState = radio.filterVoiceAutoEnabled
      self?._cwAutoCheckbox.boolState = radio.filterCwAutoEnabled
      self?._digitalAutoCheckbox.boolState = radio.filterDigitalAutoEnabled
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded)
    
    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved)
  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioHasBeenAdded(_ note: Notification) {
    
    _radio = note.object as? Radio
    
    // enable controls
    setControlStatus(true)
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable controls
    setControlStatus(false)

    _radio = nil
  }
}
