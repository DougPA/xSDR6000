//
//  ParameterMonitor.swift
//  xSDR6000
//
//  Created by Douglas Adams on 5/12/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa

// --------------------------------------------------------------------------------
// MARK: - Parameter Monitor class implementation
// --------------------------------------------------------------------------------

class ParameterMonitor: NSToolbarItem {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  open var topLimits                        : (high: Float, low: Float) = (0.0, 0.0)
  open var bottomLimits                     : (high: Float, low: Float) = (0.0, 0.0)
  
  open var colors                           : (high: NSColor, normal: NSColor, low: NSColor) = (NSColor.red, NSColor.green, NSColor.yellow)
  
  open var formatString                     = "%0.2f"
  
  open var topUnits                         = ""
  open var bottomUnits                      = ""
  
  // format & display the top value
  open var topValue: Float = 0 {
    didSet {
      if topValue > topLimits.high {
        
        topField.backgroundColor = colors.high
        
      } else if topValue < topLimits.low {
        
        topField.backgroundColor = colors.low
        
      } else {
        
        topField.backgroundColor = colors.normal
        
      }
      topField.stringValue = String(format: formatString + "\(topUnits)" , topValue)
    }
  }
  
  // format & display the bottom value
  open var bottomValue: Float = 0 {
    didSet {
      if bottomValue > bottomLimits.high {
        
        bottomField.backgroundColor = colors.high
        
      } else if bottomValue < bottomLimits.low {
        
        bottomField.backgroundColor = colors.low
        
      } else {
        
        bottomField.backgroundColor = colors.normal
      }
      bottomField.stringValue = String(format: "%0.2f\(bottomUnits)" , bottomValue)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private var topField            : NSTextField!                  // top text field
  @IBOutlet private var bottomField         : NSTextField!                  // bottom text field
  
}
