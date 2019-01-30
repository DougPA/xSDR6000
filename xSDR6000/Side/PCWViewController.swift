//
//  PCWViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/15/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PCWViewController                     : NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _compressionIndicator    : LevelIndicator!
  @IBOutlet private weak var _micLevelIndicator       : LevelIndicator!
  @IBOutlet private weak var _micProfile              : NSPopUpButton!
  @IBOutlet private weak var _micSelection            : NSPopUpButton!
  @IBOutlet private weak var _micLevel                : NSSlider!
  @IBOutlet private weak var _accButton               : NSButton!
  @IBOutlet private weak var _procButton              : NSButton!
  @IBOutlet private weak var _companderLevel          : NSSlider!
  @IBOutlet private weak var _daxButton               : NSButton!
  @IBOutlet private weak var _monButton               : NSButton!
  @IBOutlet private weak var _monLevel                : NSSlider!
  @IBOutlet private weak var _saveButton              : NSButton!
  
  private var _radio                        : Radio?

  private let kCodecOutput                  = Api.MeterShortName.codecOutput.rawValue
  private let kMicrophoneAverage            = Api.MeterShortName.microphoneAverage.rawValue
  private let kMicrophoneOutput             = Api.MeterShortName.microphoneOutput.rawValue
  private let kMicrophonePeak               = Api.MeterShortName.microphonePeak.rawValue
  private let kCompression                  = Api.MeterShortName.postClipper.rawValue

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
//    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // setup the MicLevel & Compression graphs
    setupBarGraphs()
    
    // disable all controls
    setControlState(false)
    
    // begin receiving notifications
    addNotifications()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods

  /// Respond to one of the popups
  ///
  /// - Parameter sender:             the popup
  ///
  @IBAction func popups(_ sender: NSPopUpButton)  {
    
    switch sender.identifier!.rawValue {
    case "MicProfile":
      _radio!.profiles["mic"]?.selection = sender.selectedItem!.title
    case "MicSelection":
      _radio!.transmit?.micSelection = sender.selectedItem!.title
    default:
      fatalError()
    }
  }
  /// Respond to one of the buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "Acc":
      _radio!.transmit?.micAccEnabled = sender.boolState
    case "DaxMic":
       _radio!.transmit?.daxEnabled = sender.boolState
    case "Mon":
       _radio!.transmit?.txMonitorEnabled = sender.boolState
    case "Proc":
      _radio!.transmit?.speechProcessorEnabled = sender.boolState
    case "Save":
      showDialog(sender)
    default:
      fatalError()
    }
  }
  /// Respond to one of the sliders
  ///
  /// - Parameter sender:             the slider
  ///
  @IBAction func sliders(_ sender: NSSlider) {
  
    switch sender.identifier!.rawValue {
    case "MicLevel":
     _radio!.transmit?.micLevel = sender.integerValue
    
    case "SpeechProcessorLevel":
      _radio!.transmit?.speechProcessorLevel = sender.integerValue
      
    case "TxMonitorGainSb":
      _radio!.transmit?.txMonitorGainSb = sender.integerValue
    
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Setup graph styles, legends and resting levels
  ///
  private func setupBarGraphs() {
    _compressionIndicator.style = .standard
    _micLevelIndicator.style = .standard
    
    _micLevelIndicator.legends = [
      (0, "-40", 0),
      (1, "-30", -0.5),
      (3, "-10", -0.5),
      (4, "0", -0.5),
      (nil, "Level", -0.5)
    ]
    _compressionIndicator.legends = [
      (0, "-25", 0),
      (1, "-20", -0.5),
      (4, "-5", -0.5),
      (5, "0", -1),
      (nil, "Compression", 0)
    ]
    // move the bar graphs off scale
    _micLevelIndicator.level = -250
    _micLevelIndicator.peak = -250
    _compressionIndicator.level = 20
    _compressionIndicator.peak = 20
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
      alert.messageText = "Save Mic Profile as:"
      alert.addButton(withTitle: "Save")
      
      alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
        if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        
        // save profile
        Profile.save(Profile.kMic + "_list", name: acc.stringValue)
      } )
    
    } else {
      // Delete a profile
      alert.messageText = "Delete Mic Profile:"
      alert.addButton(withTitle: "Delete")
      
      alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
        if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        
        // delete profile
        Profile.delete(Profile.kMic + "_list", name: acc.stringValue)
        self._micProfile.selectItem(at: 0)
      } )
    }
  }
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [unowned self] in
      // Popups
      self._micProfile.isEnabled = state
      self._micSelection.isEnabled = state
      
      // Sliders
      self._micLevel.isEnabled = state
      self._companderLevel.isEnabled = state
      self._monLevel.isEnabled = state

      // Buttons
      self._accButton.isEnabled = state
      self._procButton.isEnabled = state
      self._daxButton.isEnabled = state
      self._monButton.isEnabled = state
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {

    _radio = radio

    // Transmit observations
    _observations.append( radio.transmit!.observe(\.micSelection, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.micLevel, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.micAccEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.companderEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.companderLevel, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.daxEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.txMonitorEnabled, options: [.initial, .new], changeHandler: transmitChange) )
    _observations.append( radio.transmit!.observe(\.txMonitorGainSb, options: [.initial, .new], changeHandler: transmitChange) )
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
  /// Update profile value
  ///
  /// - Parameter eq:               the Profile
  ///
  private func profileChange(_ profile: Profile, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      // reload the Mic Profiles
      self._micProfile.removeAllItems()
      self._micProfile.addItems(withTitles: profile.list)
      self._micProfile.selectItem(withTitle: profile.selection)
      
      if profile.selection != "" {
        if profile.selection == "Default" {
          
          // Default is selected
          self._saveButton.title = "---"
          self._saveButton.isEnabled = false
        } else if profile.selection.first == "*" {
          
          // a selection has been modified (begins with *)
          self._saveButton.title = "Save"
          self._saveButton.isEnabled = true
        } else {
          
          // a normal selection has been made
          self._saveButton.title = "Del"
          self._saveButton.isEnabled = true
        }
      } else {
        
        // No selection
        profile.selection = "Default"
      }
    }
  }
  /// Update all control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func transmitChange(_ transmit: Transmit, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      // reload the Mic Sources
      self._micSelection.removeAllItems()
      self._micSelection.addItems(withTitles: self._radio!.micList)
      self._micSelection.selectItem(withTitle: transmit.micSelection)
      
      // set the Slider values
      self._micLevel.integerValue = transmit.micLevel
      self._companderLevel.integerValue = transmit.companderLevel
      self._monLevel.integerValue = transmit.txMonitorGainSb
      
      // set the Button states
      self._accButton.boolState = transmit.micAccEnabled
      self._procButton.boolState = transmit.speechProcessorEnabled
      self._daxButton.boolState = transmit.daxEnabled
      self._monButton.boolState = transmit.txMonitorEnabled
    }
  }
  /// Respond to changes in a Meter
  ///
  /// - Parameters:
  ///   - object:                       a Meter
  ///   - change:                       the change
  ///
  private func meterChange(_ meter: Meter, _ change: Any) {

    // which meter?
    switch meter.name {
      
    case kMicrophoneAverage:
      let value = _radio?.interlock.state == "TRANSMITTING" ||
        _radio!.transmit.metInRxEnabled ? CGFloat(meter.value) : -50
      
//      Swift.print("Mic avg = \(value)")
      DispatchQueue.main.async { self._micLevelIndicator.level = value }
      
    case kMicrophonePeak:
      let value = _radio?.interlock.state == "TRANSMITTING" ||
        _radio!.transmit.metInRxEnabled ? CGFloat(meter.value) : -50
      
//      Swift.print("Mic peak = \(value)")
      DispatchQueue.main.async { self._micLevelIndicator.peak = value }
      
    case kCompression:
      let value = _radio?.interlock.state == "TRANSMITTING" ||
        _radio!.transmit.metInRxEnabled ? CGFloat(meter.value) : 10
      
//      Swift.print("Mic comp = \(value)")
      DispatchQueue.main.async { self._compressionIndicator.level = value }
      
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

    NC.makeObserver(self, with: #selector(meterHasBeenAdded(_:)), of: .meterHasBeenAdded)
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
    _micProfile.removeAllItems()
    _micSelection.removeAllItems()
  }
  /// Process .profileHasBeenAdded Notification
  ///
  /// - Parameter note:           a Notification instance
  ///
  @objc private func profileHasBeenAdded(_ note: Notification) {
    
    let profile = note.object as! Profile
    if profile.id == Profile.kMic {
      
      // add Profile observations
      _observations.append(_radio!.profiles[Profile.kMic]!.observe(\.list, options: [.initial, .new], changeHandler: profileChange) )
      _observations.append(_radio!.profiles[Profile.kMic]!.observe(\.selection, options: [.initial, .new], changeHandler: profileChange) )
    }
  }  /// Process .meterHasBeenAdded Notification
  ///
  /// - Parameter note:             a Notification instance
  ///
  @objc private func meterHasBeenAdded(_ note: Notification) {
    
    let meter = note.object as! Meter
    
    // observe MicLevel, MicPeak & Compression
    if meter.name == kMicrophoneAverage || meter.name == kMicrophonePeak || meter.name == kCompression {     
      _observations.append( meter.observe(\.value, options: [.initial, .new], changeHandler: meterChange) )
    }
  }
}
