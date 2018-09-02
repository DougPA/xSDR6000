//
//  PCWViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/15/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class PCWViewController                         : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @objc dynamic public var radio                : Radio {
    return representedObject as! Radio }

  @objc dynamic public var micList              : [String] {
    return radio.micList.map {  return $0 == "PC" ? "MAC" : $0 }
  }

  @objc dynamic public var micSelection         : String {
    get { return (radio.transmit.micSelection  == "PC" ? "MAC" : radio.transmit.micSelection) }
    set { if newValue == "MAC" { radio.transmit.micSelection = "PC" } else { radio.transmit.micSelection = newValue }  }
  }

  @objc dynamic public var micLevel             : Float = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let kCodecOutput                  = Api.MeterShortName.codecOutput.rawValue
  private let kMicrophoneAverage            = Api.MeterShortName.microphoneAverage.rawValue
  private let kMicrophoneOutput             = Api.MeterShortName.microphoneOutput.rawValue
  private let kMicrophonePeak               = Api.MeterShortName.microphonePeak.rawValue

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // setup meter observations
    addObservations()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()

    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private var _observations                 = [NSKeyValueObservation]()
  
  /// Add observations of Meter(s)
  ///
  private func addObservations() {

    for (_, meter) in radio.meters {
      
      // is it one we need to watch?
      switch meter.name {
      case kCodecOutput, kMicrophoneAverage, kMicrophoneOutput, kMicrophonePeak:
        
        _observations.append( meter.observe(\.value, options: [.initial, .new], changeHandler: meterValue) )
        
      default:
        break
      }
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
    case kCodecOutput:

      DispatchQueue.main.async {
        self.micLevel = meter.value
//        Swift.print("\(meter.name), value = \(meter.value)")
      }

    default:
      break
    }
  }

}
