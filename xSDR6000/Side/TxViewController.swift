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
  
  @objc dynamic public var radio            : Radio {
    return representedObject as! Radio }

  @objc dynamic public var powerForward     : Float = 0
  @objc dynamic public var swr              : Float = 0

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _atuButton     : NSButton!
  @IBOutlet private weak var _atuStatus     : NSTextField!
  @IBOutlet private weak var _rfPower       : LevelIndicator!
  @IBOutlet private weak var _swr           : LevelIndicator!
  @IBOutlet private weak var _moxButton     : NSButton!
  
  private let kPowerForward                 = Api.MeterShortName.powerForward.rawValue
  private let kSwr                          = Api.MeterShortName.swr.rawValue

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup needed observations
    addObservations()

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
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func atuButton(_ sender: Any) {
    
    // initiate a tuning cycle
    radio.atu.atuStart()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations
  ///
  private func addObservations() {
    
    // Atu
    _observations.append( (radio.atu).observe(\.status, options: [.initial, .new], changeHandler: atuStatus) )
    
    // MOX
    _observations.append( radio.observe(\.mox, options: [.initial, .new], changeHandler: moxStatus) )

    // Meters
//    for (_, meter) in radio.meters {
//      
//      // is it one we need to watch?
//      if meter.name == kPowerForward || meter.name == kSwr {
//        
//        // YES, observer it
//        _observations.append( meter.observe(\.value, options: [.initial, .new], changeHandler: meterValue) )
//      }
//    }
    // is it one we need to watch?
    let meters = radio.meters.filter {$0.value.name == kPowerForward || $0.value.name == kSwr}
    meters.forEach( { _observations.append( $0.value.observe(\.value, options: [.initial, .new], changeHandler: meterValue) )} )    
  }
  /// Respond to changes in Atu status
  ///
  /// - Parameters:
  ///   - object:                       a Meter
  ///   - change:                       the change
  ///
  private func atuStatus(_ atu: Atu, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._atuButton.boolState = atu.enabled
      self._atuStatus.stringValue = atu.status
    }
  }
  /// Respond to changes in MOX status
  ///
  /// - Parameters:
  ///   - object:                       the Radio
  ///   - change:                       the change
  ///
  private func moxStatus(_ radio: Radio, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      self._moxButton.boolState = radio.mox
    }
  }
  /// Respond to changes in a Meter
  ///
  /// - Parameters:
  ///   - object:                       a Meter
  ///   - change:                       the change
  ///
  private func meterValue(_ meter: Meter, _ change: Any) {
    
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
}
