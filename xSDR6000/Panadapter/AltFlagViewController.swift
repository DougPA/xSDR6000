//
//  AltFlagViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 8/31/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class AltFlagViewController: NSViewController, NSTextFieldDelegate {
  
  static let kSliceLetters : [String]       = ["A", "B", "C", "D", "E", "F", "G", "H"]
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @objc dynamic weak var slice              : xLib6000.Slice?
  @objc dynamic weak var panadapter         : Panadapter?

  var onLeft                                = true

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _frequencyField: NSTextField!
  @IBOutlet private weak var _alpha         : NSTextField!
  
  private var _storyBoard                   : NSStoryboard?
  private var _viewController               : NSViewController?
  
  private var _position                     = NSPoint(x: 0.0, y: 0.0)
  private var _doubleClick                  : NSClickGestureRecognizer!
  private var _previousFrequency            = 0
  private var _beginEditing                 = false
  
  private let kLeftButton                   = 0x01                          // masks for Gesture Recognizers
  private let kFlagOffset                   : CGFloat = 15.0/2.0
  private let kTabViewOpen                  : CGFloat = 93.0
  private let kTabViewClosed                : CGFloat = 0.0

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // get the storyboard
    _storyBoard = NSStoryboard(name: "Flag", bundle: nil)
    
    // set the Alpha ID
    _alpha.stringValue = FlagViewController.kSliceLetters[Int(slice!.id)!]
    
    // setup Left Double Click recognizer
    _doubleClick = NSClickGestureRecognizer(target: self, action: #selector(leftDoubleClick(_:)))
    _doubleClick.buttonMask = kLeftButton
    _doubleClick.numberOfClicksRequired = 2
    _frequencyField.addGestureRecognizer(_doubleClick)
    
    _frequencyField.delegate = self
  }
  
  public func controlTextDidBeginEditing(_ note: Notification) {
    
    if let field = note.object as? NSTextField, field == _frequencyField {
      
      _previousFrequency = slice!.frequency
    }
    _beginEditing = true
  }
  
  public func controlTextDidEndEditing(_ note: Notification) {
    
    if let field = note.object as? NSTextField, field == _frequencyField, _beginEditing {
      
      repositionPanadapter(center: panadapter!.center, frequency: _previousFrequency, newFrequency: _frequencyField.integerValue)
      _beginEditing = false
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameters:
  ///   - panadapter:               a Panadapter reference
  ///   - slice:                    a Slice reference
  ///
  func configure(panadapter: Panadapter?, slice: xLib6000.Slice?) {
    self.panadapter = panadapter
    self.slice = slice!
  }
  /// Force the Frequency to be redrawn
  ///
  /// Move a Slice Flag to the specified position
  ///
  /// - Parameters:
  ///   - frequencyPosition: the desired position
  ///   - onLeft: Flag placement (Left / Right of frequency)
  ///
  func moveTo(_ frequencyPosition: NSPoint, frequency: Int, onLeft: Bool) {
    
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
    
    //    _frequencyField.integerValue = frequency
    
    view.needsDisplay = true
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Respond to Left Double Click gesture
  ///
  /// - Parameter gr: the GestureRecognizer
  ///
  @objc private func leftDoubleClick(_ gr: NSClickGestureRecognizer) {
    
    _frequencyField.selectText(self)
  }
  /// Change a Slice frequency while maintaining its position in the Panadapter display
  ///
  /// - Parameters:
  ///   - center:                   the current Panadapter center frequency
  ///   - frequency:                the current Slice frequency
  ///   - newFrequency:             the new SLice frequency
  ///
  func repositionPanadapter(center: Int, frequency: Int, newFrequency: Int) {
    
    //    Swift.print("previousCenter = \(center), newCenter = \(newFrequency - (frequency - center))")
    slice!.frequency = newFrequency
    panadapter!.center = newFrequency - (frequency - center)
  }
}
