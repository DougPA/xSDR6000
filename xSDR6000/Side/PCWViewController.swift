//
//  PCWViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/15/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PCWViewController                               : NSViewController {

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
  
  private var _radio                                  : Radio?
  private var _transmit                               : Transmit?
  private var _profile                                : Profile?

  private let kCodecOutput                  = Api.MeterShortName.codecOutput.rawValue
  private let kMicrophoneAverage            = Api.MeterShortName.microphoneAverage.rawValue
  private let kMicrophoneOutput             = Api.MeterShortName.microphoneOutput.rawValue
  private let kMicrophonePeak               = Api.MeterShortName.microphonePeak.rawValue
  private let kCompression                  = Api.MeterShortName.postClipper.rawValue
  private let kProc                         = NSUserInterfaceItemIdentifier(rawValue: "Proc")
  private let kMon                          = NSUserInterfaceItemIdentifier(rawValue: "Mon")
  private let kAcc                          = NSUserInterfaceItemIdentifier(rawValue: "Acc")
  private let kDax                          = NSUserInterfaceItemIdentifier(rawValue: "DaxMic")
  private let kMicLevel                     = NSUserInterfaceItemIdentifier(rawValue: "MicLevel")
  private let kSpeechProcessorLevel         = NSUserInterfaceItemIdentifier(rawValue: "SpeechProcessorLevel")
  private let kTxMonitorGainSb              = NSUserInterfaceItemIdentifier(rawValue: "TxMonitorGainSb")
  private let kMicProfile                   = NSUserInterfaceItemIdentifier(rawValue: "MicProfile")
  private let kMicSelection                 = NSUserInterfaceItemIdentifier(rawValue: "MicSelection")

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // setup the MicLevel & Compression graphs
    setupBarGraphs()
    
    // disable all controls
    setControlState(false)
    
    // begin receiving notifications
    addNotifications()
  }
  /// Respond to one of the popups
  ///
  /// - Parameter sender:             the popup
  ///
  @IBAction func popups(_ sender: NSPopUpButton)  {
    
    switch sender.identifier {
    case kMicProfile:
      _profile?.micProfileSelection = sender.selectedItem!.title
    case kMicSelection:
      _transmit?.micSelection = sender.selectedItem!.title
    default:
      fatalError()
    }
  }
  /// Respond to one of the buttons
  ///
  /// - Parameter sender:             the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier {
    case kProc:
      _transmit?.speechProcessorEnabled = sender.boolState
    case kMon:
      _transmit?.txMonitorEnabled = sender.boolState
    case kAcc:
      _transmit?.micAccEnabled = sender.boolState
    case kDax:
      _transmit?.daxEnabled = sender.boolState
    default:
      fatalError()
    }
  }
  /// Respond to one of the sliders
  ///
  /// - Parameter sender:             the slider
  ///
  @IBAction func sliders(_ sender: NSSlider) {
  
    switch sender.identifier {
    case kMicLevel:
      _transmit?.micLevel = sender.integerValue
    case kSpeechProcessorLevel:
      _transmit?.speechProcessorLevel = sender.integerValue
    case kTxMonitorGainSb:
      _transmit?.txMonitorGainSb = sender.integerValue
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
  /// Enable / Disable all controls
  ///
  /// - Parameter state:              true = enable
  ///
  private func setControlState(_ state: Bool) {
    
    DispatchQueue.main.async { [unowned self] in
      self._micProfile.isEnabled = state
      self._micSelection.isEnabled = state
      self._micLevel.isEnabled = state
      self._accButton.isEnabled = state
      self._procButton.isEnabled = state
      self._companderLevel.isEnabled = state
      self._daxButton.isEnabled = state
      self._monButton.isEnabled = state
      self._monLevel.isEnabled = state
    }
  }
  /// Update profile value
  ///
  /// - Parameter eq:               the Profile
  ///
  private func populateControls(_ profile: Profile) {
    
    DispatchQueue.main.async { [unowned self] in
      self._micProfile.addItems(withTitles: profile.micProfileList)
      self._micProfile.selectItem(withTitle: profile.micProfileSelection)
    }
  }
  /// Update all control values
  ///
  /// - Parameter eq:               the Transmit
  ///
  private func populateControls(_ transmit: Transmit) {
    
    DispatchQueue.main.async { [unowned self] in
      self._micSelection.addItems(withTitles: self._radio!.micList)
      self._micSelection.selectItem(withTitle: transmit.micSelection)
      self._micLevel.integerValue = transmit.micLevel
      self._accButton.boolState = transmit.micAccEnabled
      self._procButton.boolState = transmit.speechProcessorEnabled
      self._companderLevel.integerValue = transmit.companderLevel
      self._daxButton.boolState = transmit.daxEnabled
      self._monButton.boolState = transmit.txMonitorEnabled
      self._monLevel.integerValue = transmit.txMonitorGainSb
      
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations of Meter(s)
  ///
  private func addObservations(_ radio: Radio) {

    _radio = radio
    
    // Profile observations
    if let profile = radio.profile {
      _profile = profile

      _observations.append(profile.observe(\.micProfileList, options: [.initial, .new], changeHandler: profileChange) )
      _observations.append(profile.observe(\.micProfileSelection, options: [.initial, .new], changeHandler: profileChange) )
    }
    // Control observations
    if let transmit = radio.transmit {
      _transmit = transmit
      
      _observations.append( transmit.observe(\.micSelection, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.micLevel, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.micAccEnabled, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.companderEnabled, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.companderLevel, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.daxEnabled, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.txMonitorEnabled, options: [.initial, .new], changeHandler: transmitChange) )
      _observations.append( transmit.observe(\.txMonitorGainSb, options: [.initial, .new], changeHandler: transmitChange) )
    }
    // Meter observations
    let selectedMeters = radio.meters.filter {$0.value.name == kMicrophoneAverage || $0.value.name == kMicrophonePeak || $0.value.name == kCompression }
    selectedMeters.forEach { _observations.append( $0.value.observe(\.value, options: [.initial, .new], changeHandler: meterChange) ) }
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
  /// Respond to changes in profiles
  ///
  /// - Parameters:
  ///   - object:                       Profile
  ///   - change:                       the change
  ///
  private func profileChange(_ profile: Profile, _ change: Any) {
    populateControls(profile)
  }
  /// Respond to changes in controls
  ///
  /// - Parameters:
  ///   - object:                       Transmit
  ///   - change:                       the change
  ///
  private func transmitChange(_ transmit: Transmit, _ change: Any) {
    populateControls(transmit)
  }
  /// Respond to changes in a Meter
  ///
  /// - Parameters:
  ///   - object:                       a Meter
  ///   - change:                       the change
  ///
  private func meterChange(_ meter: Meter, _ change: Any) {

    // is it one we need to watch?
    switch meter.name {

    case kMicrophoneAverage:
      
      Swift.print("Mic average = \(CGFloat(meter.value))")
      
      DispatchQueue.main.async { self._micLevelIndicator.level = CGFloat(meter.value) }

    case kMicrophonePeak:

      Swift.print("Mic peak = \(CGFloat(meter.value))")

      DispatchQueue.main.async { self._micLevelIndicator.peak = CGFloat(meter.value) }

    case kCompression:
      let value = meter.value == -250 ? 0 : meter.value
      DispatchQueue.main.async { self._compressionIndicator.level = CGFloat(value) }
      
    default:
      break
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
  /// - Parameter note: a Notification instance
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
  /// - Parameter note: a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // disable all controls
    setControlState(false)
    
    // invalidate & remove observations
    invalidateObservations()
    
    _radio = nil
    _transmit = nil
    _profile = nil
    _micProfile.removeAllItems()
    _micSelection.removeAllItems()
  }
}
