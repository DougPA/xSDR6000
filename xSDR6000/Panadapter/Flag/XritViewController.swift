//
//  XritViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/7/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class XritViewController: NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _ritButton     : NSButton!
  @IBOutlet private weak var _ritZeroButton : NSButton!
  @IBOutlet private weak var _ritTextField  : NSTextField!
  @IBOutlet private weak var _ritStepper    : NSStepper!
  
  @IBOutlet private weak var _xitButton     : NSButton!
  @IBOutlet private weak var _xitZeroButton : NSButton!
  @IBOutlet private weak var _xitTextField  : NSTextField!
  @IBOutlet private weak var _xitStepper    : NSStepper!
  
  @IBOutlet private weak var _stepTextField : NSTextField!
  @IBOutlet private weak var _stepStepper   : NSStepper!
  
  private var _slice                        : xLib6000.Slice {
    return representedObject as! xLib6000.Slice }
  
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor

    // start observing
    addObservations()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the buttons
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "ritButton":
      _slice.ritEnabled = sender.boolState
    case "xitButton":
      _slice.xitEnabled = sender.boolState
    case "ritZeroButton":
      _slice.ritOffset = 0
    case "xitZeroButton":
      _slice.xitOffset = 0
    default:
      fatalError()
    }
  }
  /// Respond to one of the Steppers
  ///
  /// - Parameter sender:         the stepper
  ///
  @IBAction func steppers(_ sender: NSStepper) {
    
    switch sender.identifier!.rawValue {
    case "ritStepper":
      _slice.ritOffset = sender.integerValue
    case "xitStepper":
      _slice.xitOffset = sender.integerValue
    case "stepStepper":
      _slice.step = sender.integerValue
      
      Swift.print("integerValue = \(sender.integerValue), increment = \(sender.increment)")
      
    default:
      fatalError()
    }
  }
  /// Respond to one of the TextFields
  ///
  /// - Parameter sender:         the textfield
  ///
  @IBAction func textFields(_ sender: NSTextField) {
    
    switch sender.identifier!.rawValue {
    case "ritOffset":
      _slice.ritOffset = sender.integerValue
    case "xitOffset":
      _slice.ritOffset = sender.integerValue
    case "step":
      _slice.step = sender.integerValue
    default:
      fatalError()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      _slice.observe(\.ritEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.xitEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.ritOffset, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.xitOffset, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _slice.observe(\.step, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
    ]
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the slice being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ slice: xLib6000.Slice, _ change: Any) {
    
    DispatchQueue.main.async { [weak self] in
      self?._ritButton.boolState = slice.ritEnabled
      self?._xitButton.boolState = slice.xitEnabled

      self?._ritTextField.integerValue = slice.ritOffset
      self?._ritStepper.integerValue = slice.ritOffset

      self?._xitTextField.integerValue = slice.xitOffset
      self?._xitStepper.integerValue = slice.xitOffset

      self?._stepTextField.integerValue = slice.step
      self?._stepStepper.integerValue = slice.step
    }
  }
}
