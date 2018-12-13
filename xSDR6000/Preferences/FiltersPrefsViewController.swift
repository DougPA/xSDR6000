//
//  FiltersPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/13/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class FiltersPrefsViewController            : NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  @IBOutlet private weak var _voiceAutoCheckbox     : NSButton!
  @IBOutlet private weak var _cwAutoCheckbox        : NSButton!
  @IBOutlet private weak var _digitalAutoCheckbox   : NSButton!
  
  private var _radio                        = Api.sharedInstance.radio

  private let kVoiceAuto                    = NSUserInterfaceItemIdentifier(rawValue: "VoiceAuto")
  private let kCwAuto                       = NSUserInterfaceItemIdentifier(rawValue: "CwAuto")
  private let kDigitalAuto                  = NSUserInterfaceItemIdentifier(rawValue: "DigitalAuto")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // enable/disable all controls
    setControlState( _radio != nil )
    
    if let radio = _radio { addObservations(radio) }
    
    // begin receiving notifications
    addNotifications()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func checkBoxes(_ sender: NSButton) {
    switch sender.identifier {
    case kVoiceAuto:
      _radio?.filterVoiceAutoEnabled = sender.boolState
    case kCwAuto:
      _radio?.filterCwAutoEnabled = sender.boolState
    case kDigitalAuto:
      _radio?.filterDigitalAutoEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [weak self] in
      // Filters
      self?._voiceAutoCheckbox.isEnabled = state
      self?._cwAutoCheckbox.isEnabled = state
      self?._digitalAutoCheckbox.isEnabled = state
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {
    
    _radio = radio
    
    // Radio observations
    _observations.append( radio.observe(\.filterVoiceAutoEnabled, options: [.initial, .new], changeHandler: radioChange) )
    // Radio observations
    _observations.append( radio.observe(\.filterCwAutoEnabled, options: [.initial, .new], changeHandler: radioChange) )
    // Radio observations
    _observations.append( radio.observe(\.filterDigitalAutoEnabled, options: [.initial, .new], changeHandler: radioChange) )

  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(remove: Bool = true) {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // if specified, remove the tokens
    if remove { _observations.removeAll() }
  }
  /// Update all Radio control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func radioChange(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      // Filters
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
    
    if let radio = note.object as? Radio {
      
      // begin observing parameters
      addObservations(radio)
      
      // enable all controls
      setControlState(true)
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    setControlState(false)
    
    // invalidate & remove observations
    invalidateObservations()
    
    _radio = nil
  }
}
