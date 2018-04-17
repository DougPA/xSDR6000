//
//  FlagViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/22/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Flag View Controller class implementation
// --------------------------------------------------------------------------------

class FlagViewController                    : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @objc weak var slice                      : xLib6000.Slice?
  internal var onLeft                       = true
  internal var observations                 = [NSKeyValueObservation]()

  private var _position                     = NSPoint(x: 0.0, y: 0.0)

  private let kFlagOffset                   : CGFloat = 15.0/2.0
    
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    Swift.print("FlagViewController - viewDidLoad")

    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor.lightGray.cgColor
  }
  
//  deinit {
//
//    Swift.print("FlagViewController - deinit")
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Move a Slice Flag to the specified position
  ///
  /// - Parameters:
  ///   - frequencyPosition: the desired position
  ///   - onLeft: Flag placement (Left / Right of frequency)
  ///
  func moveTo(_ frequencyPosition: NSPoint, onLeft: Bool) {
        
    self.onLeft = onLeft
    
    // What side should the Flag be on?
    if onLeft {
      
      // LEFT
      _position.x = frequencyPosition.x - view.frame.width - kFlagOffset
      
    } else {
      
      // RIGHT
      _position.x = frequencyPosition.x + kFlagOffset
    }
    _position.y = frequencyPosition.y
    
    // update the flag's position
    view.setFrameOrigin(_position)
  }
}
