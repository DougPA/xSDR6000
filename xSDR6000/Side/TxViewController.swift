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
  // MARK: - Public properties
  
  @objc dynamic public var powerForward     : Float = 0
  @objc dynamic public var swr              : Float = 0

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _tuneButton    : NSButton!
  @IBOutlet private weak var _moxButton     : NSButton!
  @IBOutlet private weak var _atuButton     : NSButton!
  @IBOutlet private weak var _memButton     : NSButton!

  @IBOutlet private weak var _txProfile     : NSPopUpButton!
  @IBOutlet private weak var _atuStatus     : NSTextField!

  @IBOutlet private weak var _tunePowerSlider : NSSlider!
  @IBOutlet private weak var _tunePowerLevel  : NSTextField!
  @IBOutlet private weak var _rfPowerSlider   : NSSlider!
  @IBOutlet private weak var _rfPowerLevel    : NSTextField!
  
  @IBOutlet private weak var _rfPower       : LevelIndicator!
  @IBOutlet private weak var _swr           : LevelIndicator!
  
  
  
  private var _radio                        : Radio?

  private let kPowerForward                 = Api.MeterShortName.powerForward.rawValue
  private let kSwr                          = Api.MeterShortName.swr.rawValue

  private let kTune                         = NSUserInterfaceItemIdentifier(rawValue: "Tune")
  private let kMox                          = NSUserInterfaceItemIdentifier(rawValue: "Mox")
  private let kAtu                          = NSUserInterfaceItemIdentifier(rawValue: "Atu")
  private let kMem                          = NSUserInterfaceItemIdentifier(rawValue: "Mem")
  private let kTunePower                    = NSUserInterfaceItemIdentifier(rawValue: "TunePower")
  private let kRfPower                      = NSUserInterfaceItemIdentifier(rawValue: "RfPower")

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    _rfPower.style = .standard
    _swr.style = .standard

    _rfPower.legends = [            // to skip a legend pass "" as the format
      (0, "0", 0),
      (4, "40", -0.5),
      (8, "80", -0.5),
      (10, "100", -0.5),
      (12, "120", -1),
      (nil, "RF Pwr", 0)
    ]
    _swr.legends = [
      (0, "0", 0),
      (2, "1.5", -0.5),
      (6, "2.5", -0.5),
      (8, "3", -1),
      (nil, "SWR", 0)
    ]
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
  /// Update all control values
  ///
  /// - Parameter eq:               the Radio
  ///
  private func populateControls(_ radio: Radio) {
    
    DispatchQueue.main.async { [unowned self] in
      self._tuneButton.boolState = radio.transmit.tune
      self._moxButton.boolState = radio.mox
      self._atuButton.boolState = radio.atu.enabled
      self._memButton.boolState = radio.atu.memoriesEnabled
      
      self._txProfile.selectItem(withTitle: radio.profile.txProfileSelection)
      self._atuStatus.stringValue = radio.atu.status
      
      self._tunePowerSlider.integerValue = radio.transmit.tunePower
      self._tunePowerLevel.integerValue = radio.transmit.tunePower
      self._rfPowerSlider.integerValue = radio.transmit.rfPower
      self._rfPowerLevel.integerValue = radio.transmit.rfPower
      
      self._txProfile.addItems(withTitles: self._radio!.profile.txProfileList)
      self._txProfile.selectItem(withTitle: self._radio!.profile.txProfileSelection)
    }
  }
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations(_ radio: Radio) {
    
    // Radio observations
    _observations.append( radio.transmit.observe(\.tune, options: [.initial, .new], changeHandler: radioChange) )
    _observations.append( radio.observe(\.mox, options: [.initial, .new], changeHandler: radioChange) )
    _observations.append( radio.atu.observe(\.enabled, options: [.initial, .new], changeHandler: radioChange) )
    _observations.append( radio.atu.observe(\.memoriesEnabled, options: [.initial, .new], changeHandler: radioChange) )
    
    _observations.append( radio.profile.observe(\.txProfileSelection, options: [.initial, .new], changeHandler: radioChange) )
    _observations.append( radio.atu.observe(\.status, options: [.initial, .new], changeHandler: radioChange) )
    
    _observations.append( radio.transmit.observe(\.tunePower, options: [.initial, .new], changeHandler: radioChange) )
    _observations.append( radio.transmit.observe(\.rfPower, options: [.initial, .new], changeHandler: radioChange) )
    
    // Meter observations
    let meters = radio.meters.filter {$0.value.name == kPowerForward || $0.value.name == kSwr}
    meters.forEach { _observations.append( $0.value.observe(\.value, options: [.initial, .new], changeHandler: meterChange)) }
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
  /// Respond to changes in MOX status
  ///
  /// - Parameters:
  ///   - object:                       the Radio
  ///   - change:                       the change
  ///
  private func radioChange(_ object: Any, _ change: Any) {
    
    populateControls(_radio!)
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
    case kPowerForward:
      
      DispatchQueue.main.async {
        // kPowerForward is in Dbm
        self._rfPower.level = CGFloat(meter.value.powerFromDbm)
      }
    case kSwr:
      DispatchQueue.main.async {
        // kSwr is actual SWR value
        self._swr.level = CGFloat(meter.value)
      }

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
      
      _radio = radio
      
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
  }
}
