//
//  RadioPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/15/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class RadioPrefsViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private  properties
  
  @IBOutlet private weak var _serialNumberTextField       : NSTextField!
  @IBOutlet private weak var _hwVersionTextField          : NSTextField!
  @IBOutlet private weak var _optionsTextField            : NSTextField!
  @IBOutlet private weak var _modelTextField              : NSTextField!
  @IBOutlet private weak var _callsignTextField           : NSTextField!
  @IBOutlet private weak var _nicknameTextField           : NSTextField!
  
  @IBOutlet private weak var _remoteOnEnabledCheckbox     : NSButton!
  @IBOutlet private weak var _flexControlEnabledCheckbox  : NSButton!
  
  @IBOutlet private weak var _modelRadioButton            : NSButton!
  @IBOutlet private weak var _callsignRadioButton         : NSButton!
  @IBOutlet private weak var _nicknameRadioButton         : NSButton!
  
  private var _radio                        : Radio?
  private var _observations                 = [NSKeyValueObservation]()

  // ----------------------------------------------------------------------------
  // MARK: - Overridden  methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // check for an active radio
    if let radio = Api.sharedInstance.radio { _radio = radio ; enableControls(true) }
    
    // start receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action  methods
  
  @IBAction func regionChange(_ sender: NSButton) {
    
    // TODO: add code
    
    notImplemented(sender.title).beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in } )
  }
  
  @IBAction func screensaver(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "Model":
      _radio!.radioScreenSaver = "model"
      
    case "Callsign":
      _radio!.radioScreenSaver = "callsign"
      
    case "Nickname":
      _radio!.radioScreenSaver = "nickname"
      
    default:
      fatalError()
    }
  }
  
  @IBAction func textFields(_ sender: NSTextField) {
    
    switch sender.identifier!.rawValue {
    case "CallsignText":
      _radio!.callsign = sender.stringValue
      
    case "NicknameText":
      _radio!.nickname = sender.stringValue
      
    default:
      fatalError()
    }
  }
  
  @IBAction func checkboxes(_ sender: NSButton) {

    switch sender.identifier!.rawValue {
    case "RemoteOn":
      _radio!.remoteOnEnabled = sender.boolState
      
//    case "FlexControl":
//      _radio!.flexControlEnabled = sender.boolState
      
    default:
      fatalError()
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Enable / Disable controls
  ///
  /// - Parameter status:             true = enable
  ///
  private func enableControls(_ state: Bool = true) {
    
    if state {
      
      addObservations()
    } else {
      
      removeObservations()
    }
    DispatchQueue.main.async { [weak self] in
      self?._serialNumberTextField.isEnabled = state
      self?._hwVersionTextField.isEnabled = state
      self?._optionsTextField.isEnabled = state
      self?._modelTextField.isEnabled = state
      self?._callsignTextField.isEnabled = state
      self?._nicknameTextField.isEnabled = state
      
      self?._remoteOnEnabledCheckbox.isEnabled = state
      //      self._flexControlEnabledCheckbox = radio.flex
      
      self?._modelRadioButton.isEnabled = state
      self?._callsignRadioButton.isEnabled = state
      self?._nicknameRadioButton.isEnabled = state
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _radio!.observe(\.serialNumber, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.version, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.radioOptions, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.radioModel, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.callsign, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.nickname, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.remoteOnEnabled, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
//      _radio!.observe(\.flexControlEnabled, options: [.initial, .new], changeHandler: radioHandler(_:_:)),
      _radio!.observe(\.radioScreenSaver, options: [.initial, .new], changeHandler: radioHandler(_:_:))
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
  ///   - profile:                  the Radio being observed
  ///   - change:                   the change
  ///
  private func radioHandler(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._serialNumberTextField.stringValue = radio.serialNumber
      self?._hwVersionTextField.stringValue = radio.version
      self?._optionsTextField.stringValue = radio.radioOptions
      self?._modelTextField.stringValue = radio.radioModel
      self?._callsignTextField.stringValue = radio.callsign
      self?._nicknameTextField.stringValue = radio.nickname

      self?._remoteOnEnabledCheckbox.boolState = radio.remoteOnEnabled
//      self._flexControlEnabledCheckbox = radio.flexControlEnabled
      
      self?._modelRadioButton.boolState = (radio.radioScreenSaver == "model")
      self?._callsignRadioButton.boolState = (radio.radioScreenSaver == "callsign")
      self?._nicknameRadioButton.boolState = (radio.radioScreenSaver == "nickname")
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
    enableControls()
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable controls
    enableControls(false)
    
    _radio = nil
  }
}
