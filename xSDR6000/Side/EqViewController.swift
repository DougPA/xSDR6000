//
//  EqViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/1/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults

// --------------------------------------------------------------------------------
// MARK: - Radio View Controller class implementation
// --------------------------------------------------------------------------------

final class EqViewController                : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var onButton       : NSButton!                     // buttons
  @IBOutlet private weak var rxButton       : NSButton!
  @IBOutlet private weak var txButton       : NSButton!
  @IBOutlet private weak var slider0        : NSSlider!                     // sliders
  @IBOutlet private weak var slider1        : NSSlider!
  @IBOutlet private weak var slider2        : NSSlider!
  @IBOutlet private weak var slider3        : NSSlider!
  @IBOutlet private weak var slider4        : NSSlider!
  @IBOutlet private weak var slider5        : NSSlider!
  @IBOutlet private weak var slider6        : NSSlider!
  @IBOutlet private weak var slider7        : NSSlider!
  
  private var _equalizerRx                  : Equalizer!                    // Rx Equalizer
  private var _equalizerTx                  : Equalizer!                    // Tx Equalizer
  private var _eq                           : Equalizer!                    // Current Equalizer
  
  private let kEqOn                         = NSUserInterfaceItemIdentifier(rawValue: "EqOn")
  private let kEqRx                         = NSUserInterfaceItemIdentifier(rawValue: "EqRx")
  private let kEqTx                         = NSUserInterfaceItemIdentifier(rawValue: "EqTx")
  private let kLevel63Hz                    = NSUserInterfaceItemIdentifier(rawValue: "Level63Hz")
  private let kLevel125Hz                   = NSUserInterfaceItemIdentifier(rawValue: "Level125Hz")
  private let kLevel250Hz                   = NSUserInterfaceItemIdentifier(rawValue: "Level250Hz")
  private let kLevel500Hz                   = NSUserInterfaceItemIdentifier(rawValue: "Level500Hz")
  private let kLevel1000Hz                  = NSUserInterfaceItemIdentifier(rawValue: "Level1000Hz")
  private let kLevel2000Hz                  = NSUserInterfaceItemIdentifier(rawValue: "Level2000Hz")
  private let kLevel4000Hz                  = NSUserInterfaceItemIdentifier(rawValue: "Level4000Hz")
  private let kLevel8000Hz                  = NSUserInterfaceItemIdentifier(rawValue: "Level8000Hz")

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    // disable all controls
    setControlState(false)
    
    // begin receiving notifications
    addNotifications()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the buttons
  ///
  /// - Parameter sender:           the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier {
      
    case kEqOn:
      // set the displayed Equalizer On / Off
      _eq!.eqEnabled = onButton.boolState

    case kEqRx:
      // select the Rx equalizer
      _eq = _equalizerRx
      Defaults[.eqRxSelected] = sender.boolState

    case kEqTx:
      // select the Tx equalizer
      _eq = _equalizerTx
      Defaults[.eqRxSelected] = !sender.boolState
      
    default:
      fatalError()
    }    
    // populate the controls of the selected Equalizer
    populateControls( _eq)
  }
  /// Respond to changes in a slider value
  ///
  /// - Parameter sender:           the slider
  ///
  @IBAction func slider(_ sender: NSSlider) {
    
    // tell the Radio to change the Eq setting
    switch sender.identifier {
    case kLevel63Hz:
      _eq.level63Hz = sender.integerValue
    case kLevel125Hz:
      _eq.level125Hz = sender.integerValue
    case kLevel250Hz:
      _eq.level250Hz = sender.integerValue
    case kLevel500Hz:
      _eq.level500Hz = sender.integerValue
    case kLevel1000Hz:
      _eq.level1000Hz = sender.integerValue
    case kLevel2000Hz:
      _eq.level2000Hz = sender.integerValue
    case kLevel4000Hz:
      _eq.level4000Hz = sender.integerValue
    case kLevel8000Hz:
      _eq.level8000Hz = sender.integerValue
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
      
      self.rxButton.isEnabled = state
      self.txButton.isEnabled = state
      
      self.onButton.isEnabled = state
      
      self.slider0.isEnabled = state
      self.slider1.isEnabled = state
      self.slider2.isEnabled = state
      self.slider3.isEnabled = state
      self.slider4.isEnabled = state
      self.slider5.isEnabled = state
      self.slider6.isEnabled = state
      self.slider7.isEnabled = state
    }
  }
  /// Update all control values
  ///
  /// - Parameter eq:               the Equalizer
  ///
  private func populateControls(_ eq: Equalizer) {
    
    DispatchQueue.main.async { [unowned self] in
      
      // enable the appropriate Equalizer
      self.rxButton.boolState = Defaults[.eqRxSelected]
      self.txButton.boolState = !Defaults[.eqRxSelected]
      
      // set the ON button state
      self.onButton.boolState = eq.eqEnabled
      
      // set the slider values
      self.slider0.integerValue = eq.level63Hz
      self.slider1.integerValue = eq.level125Hz
      self.slider2.integerValue = eq.level250Hz
      self.slider3.integerValue = eq.level500Hz
      self.slider4.integerValue = eq.level1000Hz
      self.slider5.integerValue = eq.level2000Hz
      self.slider6.integerValue = eq.level4000Hz
      self.slider7.integerValue = eq.level8000Hz
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods

  private var _observations                 = [NSKeyValueObservation]()

  /// Add observations of parameters
  ///
  private func addObservations() {
    
    if let rx = _equalizerRx {
      _observations.append( rx.observe(\.level63Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level125Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level250Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level500Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level1000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level2000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level4000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.level8000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( rx.observe(\.eqEnabled, options: [.initial, .new], changeHandler: paramChange) )
    }
    
    if let tx = _equalizerTx {
      _observations.append( tx.observe(\.level63Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level125Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level250Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level500Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level1000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level2000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level4000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.level8000Hz, options: [.initial, .new], changeHandler: paramChange) )
      _observations.append( tx.observe(\.eqEnabled, options: [.initial, .new], changeHandler: paramChange) )
    }
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
  /// Respond to changes in parameters
  ///
  /// - Parameters:
  ///   - object:                       an Equalizer
  ///   - change:                       the change
  ///
  private func paramChange(_ eq: Equalizer, _ change: Any) {
    
    // update the Equalizer if currently displayed
    if eq == _eq {
      populateControls(eq)
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
      // get a reference to each equalizer
      _equalizerRx = radio.equalizers[.rxsc]
      _equalizerTx = radio.equalizers[.txsc]
      
      // begin observing parameters
      addObservations()
      
      // save a reference to the selected Equalizer
      _eq = (Defaults[.eqRxSelected] ? _equalizerRx : _equalizerTx)!
      
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
    
    _equalizerRx = nil
    _equalizerTx = nil
    _eq = nil
  }
}
