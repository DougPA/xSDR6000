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
  
//  @objc dynamic public var radio                : Radio {
//    return representedObject as! Radio }
//
//  @objc dynamic public var micList              : [String] {
//    return radio.micList.map {  return $0 == "PC" ? "MAC" : $0 }
//  }
//
//  @objc dynamic public var micSelection         : String {
//    get { return (radio.transmit.micSelection  == "PC" ? "MAC" : radio.transmit.micSelection) }
//    set { if newValue == "MAC" { radio.transmit.micSelection = "PC" } else { radio.transmit.micSelection = newValue }  }
//  }

  @IBOutlet private weak var compressionIndicator   : LevelIndicator!
  @IBOutlet private weak var micLevelIndicator      : LevelIndicator!

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _radio                        = Api.sharedInstance.radio {
    didSet { addObservations() }
  }
  
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
    
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
    micLevelIndicator.legends = [
      (0, "-40", 0),
      (1, "-30", -0.5),
      (3, "-10", -0.5),
      (4, "0", -0.5),
      (nil, "Level", -0.5)
    ]
    compressionIndicator.legends = [
      (0, "-25", 0),
      (1, "-20", -0.5),
      (4, "-5", -0.5),
      (5, "0", -1),
      (nil, "Compression", 0)
    ]
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

    if let radio = _radio {
      // is it one we need to watch?
      let meters = radio.meters.filter {$0.value.name == kMicrophoneAverage || $0.value.name == kMicrophonePeak || $0.value.name == kCompression }
      meters.forEach { _observations.append( $0.value.observe(\.value, options: [.initial, .new], changeHandler: meterValue) ) }
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

    case kMicrophoneAverage:

      DispatchQueue.main.async {
        self.micLevelIndicator.level = CGFloat(meter.value)
      }

    case kMicrophonePeak:
      
      DispatchQueue.main.async {
        self.micLevelIndicator.peak = CGFloat(meter.value)
      }

    case kCompression:
      
      let value = meter.value == -250 ? 0 : meter.value
      
      DispatchQueue.main.async {
        self.compressionIndicator.level = CGFloat(value)
      }
      
    default:
      break
    }
  }

}
