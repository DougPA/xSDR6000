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

  @IBOutlet private weak var compressionIndicator   : LevelIndicator!
  @IBOutlet private weak var micLevelIndicator      : LevelIndicator!

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let kCodecOutput                  = Api.MeterShortName.codecOutput.rawValue
  private let kMicrophoneAverage            = Api.MeterShortName.microphoneAverage.rawValue
  private let kMicrophoneOutput             = Api.MeterShortName.microphoneOutput.rawValue
  private let kMicrophonePeak               = Api.MeterShortName.microphonePeak.rawValue
  private let kCompression                  = Api.MeterShortName.postClipper.rawValue

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    micLevelIndicator.legends = [            // to skip a legend pass "" as the format
      (0, "%1d", -40, 0),
      (1, "%2d", -30, -0.5),
      (3, "%2d", -10, -0.5),
      (4, "%1d", 0, -0.5),
      (nil, "Level", 0, -0.5)
    ]
    compressionIndicator.legends = [
      (0, "%2d", -25, 0),
      (1, "%2d", -20, -0.5),
      (4, "%2d", -5, -0.5),
      (5, "%3d", 0, -1),
      (nil, "Compression", 0, 0)
    ]

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
      case kMicrophoneAverage, kMicrophonePeak, kCompression:
        
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
