//
//  TxViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 8/31/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class TxViewController                      : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _tuneButton        : NSButton!
  @IBOutlet private weak var _moxButton         : NSButton!
  @IBOutlet private weak var _atuButton         : NSButton!
  @IBOutlet private weak var _memButton         : NSButton!
  @IBOutlet private weak var _txProfile         : NSPopUpButton!
  @IBOutlet private weak var _atuStatus         : NSTextField!
  @IBOutlet private weak var _tunePowerSlider   : NSSlider!
  @IBOutlet private weak var _tunePowerLevel    : NSTextField!
  @IBOutlet private weak var _rfPowerSlider     : NSSlider!
  @IBOutlet private weak var _rfPowerLevel      : NSTextField!
  @IBOutlet private weak var _rfPowerIndicator  : LevelIndicator!
  @IBOutlet private weak var _swrIndicator      : LevelIndicator!
  
  private var _radio                        : Radio?

  private let kPowerForward                 = Api.MeterShortName.powerForward.rawValue
  private let kSwr                          = Api.MeterShortName.swr.rawValue
  private let kTune                         = NSUserInterfaceItemIdentifier(rawValue: "Tune")
  private let kMox                          = NSUserInterfaceItemIdentifier(rawValue: "Mox")
  private let kAtu                          = NSUserInterfaceItemIdentifier(rawValue: "Atu")
  private let kMem                          = NSUserInterfaceItemIdentifier(rawValue: "Mem")
  private let kTunePower                    = NSUserInterfaceItemIdentifier(rawValue: "TunePower")
  private let kRfPower                      = NSUserInterfaceItemIdentifier(rawValue: "RfPower")
  private let kSave                         = NSUserInterfaceItemIdentifier(rawValue: "Save")

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // setup the RfPower & Swr graphs
    setupBarGraphs()

    // disable all controls
    setControlState(false)
    
    // begin receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier {
      case kTune:
        _radio?.transmit.tune = sender.boolState
      case kMox:
        _radio?.mox = sender.boolState
      case kAtu:
        // initiate a tuning cycle
        _radio?.atu.atuStart()
      case kMem:
        _radio?.atu.memoriesEnabled = sender.boolState
      case kSave:
        showDialog(sender)
      default:
        fatalError()
    }
  }
  @IBAction func sliders(_ sender: NSSlider) {
    switch sender.identifier {

    case kTunePower:
      _radio?.transmit.tunePower = sender.integerValue
    case kRfPower:
      _radio?.transmit.rfPower = sender.integerValue
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Setup graph styles, legends and resting levels
  ///
  private func setupBarGraphs() {
    _rfPowerIndicator.style = .standard
    _swrIndicator.style = .standard
    
    _rfPowerIndicator.legends = [            // to skip a legend pass "" as the format
      (0, "0", 0),
      (4, "40", -0.5),
      (8, "80", -0.5),
      (10, "100", -0.5),
      (12, "120", -1),
      (nil, "RF Pwr", 0)
    ]
    _swrIndicator.legends = [
      (0, "0", 0),
      (2, "1.5", -0.5),
      (6, "2.5", -0.5),
      (8, "3", -1),
      (nil, "SWR", 0)
    ]
    // move the bar graphs off scale
    _rfPowerIndicator.level = -10
    _rfPowerIndicator.peak = -10
    _swrIndicator.level = -10
    _swrIndicator.peak = -10
  }
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [unowned self] in
      self._tuneButton.isEnabled = state
      self._moxButton.isEnabled = state
      self._atuButton.isEnabled = state
      self._memButton.isEnabled = state
      self._txProfile.isEnabled = state
      self._tunePowerSlider.isEnabled = state
      self._rfPowerSlider.isEnabled = state
    }
  }
  /// Show a Save / Delete profile dialog
  ///
  /// - Parameter sender:             a button
  ///
  private func showDialog(_ sender: NSButton) {
    let alert = NSAlert()
    let acc = NSTextField(frame: NSMakeRect(0, 0, 233, 25))
    acc.stringValue = _radio!.profiles["mic"]!.selection
    acc.isEditable = true
    acc.drawsBackground = true
    alert.accessoryView = acc
    alert.addButton(withTitle: "Cancel")
    
    // ask the user to confirm
    if sender.title == "Save" {
      // Save a Profile
      alert.messageText = "Save Tx Profile as:"
      alert.addButton(withTitle: "Save")
      
      alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
        if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        
        // save profile
        Profile.save(Profile.kTx + "_list", name: acc.stringValue)
      } )
      
    } else {
      // Delete a profile
      alert.messageText = "Delete Tx Profile:"
      alert.addButton(withTitle: "Delete")
      
      alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
        if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        
        // delete profile
        Profile.delete(Profile.kTx + "_list", name: acc.stringValue)
        self._txProfile.selectItem(at: 0)
      } )
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {
    
    // Atu parameters
    _observations.append( radio.atu.observe(\.status, options: [.initial, .new], changeHandler: atuChange) )
    _observations.append( radio.atu.observe(\.enabled, options: [.initial, .new], changeHandler: atuChange) )
    _observations.append( radio.atu.observe(\.memoriesEnabled, options: [.initial, .new], changeHandler: atuChange) )
    
    // Meter parameters
    let meters = radio.meters.filter {$0.value.name == kPowerForward || $0.value.name == kSwr}
    meters.forEach { _observations.append( $0.value.observe(\.value, options: [.initial, .new], changeHandler: meterChange)) }

    // Radio parameters
    _observations.append( radio.observe(\.mox, options: [.initial, .new], changeHandler: radioChange) )
    
    // Transmit parameters
    _observations.append( radio.transmit.observe(\.tune, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit.observe(\.tunePower, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit.observe(\.rfPower, options: [.initial, .new], changeHandler: transmitChange) )
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
  /// Update all Atu control values
  ///
  /// - Parameter atu:               Atu object
  ///
  private func atuChange(_ atu: Atu, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._atuButton.boolState = atu.enabled
      self._memButton.boolState = atu.memoriesEnabled
      self._atuStatus.stringValue = atu.status
    }
  }
  /// Update all Profile control values
  ///
  /// - Parameter profile:               Profile object
  ///
  private func profileChange(_ profile: Profile, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._txProfile.removeAllItems()
      self._txProfile.addItems(withTitles: profile.list)
      self._txProfile.selectItem(withTitle: profile.selection)
    }
  }
  /// Update all control values
  ///
  /// - Parameter radio:               Radio object
  ///
  private func radioChange(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._moxButton.boolState = radio.mox
    }
  }
  /// Update all Transmit control values
  ///
  /// - Parameter transmit:               Transmit
  ///
  private func transmitChange(_ transmit: Transmit, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._tuneButton.boolState = transmit.tune
      self._tunePowerSlider.integerValue = transmit.tunePower
      self._tunePowerLevel.integerValue = transmit.tunePower
      self._rfPowerSlider.integerValue = transmit.rfPower
      self._rfPowerLevel.integerValue = transmit.rfPower
    }
  }
  /// Update a Meter
  ///
  /// - Parameters:
  ///   - object:                       a Meter
  ///   - change:                       the change
  ///
  private func meterChange(_ meter: Meter, _ change: Any) {
    
    switch meter.name {
    case kPowerForward:                     // kPowerForward is in Dbm
      DispatchQueue.main.async { self._rfPowerIndicator.level = CGFloat(meter.value.powerFromDbm) }
    
    case kSwr:                              // kSwr is actual SWR value
      DispatchQueue.main.async { self._swrIndicator.level = CGFloat(meter.value)  }
    
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded)
    
    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved)
    
    NC.makeObserver(self, with: #selector(profileHasBeenAdded(_:)), of: .profileHasBeenAdded)
  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note:           a Notification instance
  ///
  @objc private func radioHasBeenAdded(_ note: Notification) {
    
    if let radio = note.object as? Radio {
      
      _radio = radio
      
      // begin observing parameters
      addObservations(radio)
      
      // enable all controls
      setControlState(true)
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:           a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    setControlState(false)
    
    // invalidate & remove observations
    invalidateObservations()
    
    _radio = nil
  }
  /// Process .profileHasBeenAdded Notification
  ///
  /// - Parameter note:           a Notification instance
  ///
  @objc private func profileHasBeenAdded(_ note: Notification) {
    
    let profile = note.object as! Profile
    if profile.id == Profile.kTx {

      // add Mic Profile observations
      _observations.append( _radio!.profiles[Profile.kTx]!.observe(\.list, options: [.initial, .new], changeHandler: profileChange) )
      _observations.append( _radio!.profiles[Profile.kTx]!.observe(\.selection, options: [.initial, .new], changeHandler: profileChange) )
    }
  }
}
