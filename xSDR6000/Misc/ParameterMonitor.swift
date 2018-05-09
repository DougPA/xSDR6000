//
//  ParameterMonitor.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Parameter Monitor class implementation
// --------------------------------------------------------------------------------

class ParameterMonitor: NSToolbarItem {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var colors                         : (high: NSColor, normal: NSColor, low: NSColor) = (NSColor.red, NSColor.green, NSColor.yellow)
  public var formatString                   = "%0.2f"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private var topField            : NSTextField!
  @IBOutlet private var bottomField         : NSTextField!

  private weak var _radio                   : Radio?
  private var _id                           : NSToolbarItem.Identifier
  private var _meterShortNames              = [Api.MeterShortName]()
  private var _units                        = [String]()
  private var _observations                 = [NSKeyValueObservation]()
  
  private let kTopValue                     = 0
  private let kBottomValue                  = 1

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  override init(itemIdentifier: NSToolbarItem.Identifier) {
    _id = itemIdentifier
    
    super.init(itemIdentifier: itemIdentifier)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Activate this Parameter Monitor
  ///
  /// - Parameters:
  ///   - radio:              a reference to the Radio class
  ///   - meterShortNames:    an array of MeterShortNames
  ///   - units:              an array of units
  ///
  func activate(radio: Radio, meterShortNames: [Api.MeterShortName], units: [String]) {
    
    _radio = radio
    _meterShortNames = meterShortNames
    _units = units
    
    // for the first two short names (others are ignored)
    for i in kTopValue...kBottomValue {
      
      // is there a Meter by that name?
      if let meter = Meter.findBy(shortName: _meterShortNames[i].rawValue) {
        
        // YES, observe it's value
        _observations.append( meter.observe(\.value, options: [.new],changeHandler: updateValue))
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Update the value of the ParameterMonitor
  ///
  /// - Parameters:
  ///   - object:             an observed object
  ///   - change:             a change dictionary
  ///
  private func updateValue(_ object: Any, _ change: Any) {

    let meter = object as! Meter

    // which Meter?
    switch meter.name {
    case _meterShortNames[kTopValue].rawValue:
      // top one
      updateField(topField, for: meter, units: _units[kTopValue])

    case _meterShortNames[kBottomValue].rawValue:
      // bottom one
      updateField(bottomField, for: meter, units: _units[kBottomValue])

    default:
      // should never happen
      break
    }
  }
  /// Update a field
  ///
  /// - Parameters:
  ///   - field:              the textfield
  ///   - meter:              a reference to a Meter
  ///   - units:              the units
  ///
  private func updateField(_ field: NSTextField, for meter: Meter, units: String) {
    
    DispatchQueue.main.async { [unowned self] in
      
      // determine the background color
      switch meter.value {
      case ...meter.low:                                    // < low
        field.backgroundColor = self.colors.low
      case meter.high...:                                   // > high
        field.backgroundColor = self.colors.high
      case meter.low...meter.high:                          // between low & high
        field.backgroundColor = self.colors.normal
      default:                                              // should never happen
        field.backgroundColor = self.colors.normal
      }
      // set the field value
      field.stringValue = String(format: self.formatString + " \(units)" , meter.value)
    }
  }
}
