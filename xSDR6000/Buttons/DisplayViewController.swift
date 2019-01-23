//
//  DisplayViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/7/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults

class DisplayViewController: NSViewController, NSPopoverDelegate {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _averageSlider           : NSSlider!
  @IBOutlet private weak var _averageTextField        : NSTextField!
  @IBOutlet private weak var _framesSlider            : NSSlider!
  @IBOutlet private weak var _framesTextField         : NSTextField!
  @IBOutlet private weak var _fillSlider              : NSSlider!
  @IBOutlet private weak var _fillTextField           : NSTextField!

  @IBOutlet private weak var _weightedAverageCheckbox : NSButton!

  @IBOutlet private weak var _colorGainSlider         : NSSlider!
  @IBOutlet private weak var _colorGainTextField      : NSTextField!
  @IBOutlet private weak var _blackLevelSlider        : NSSlider!
  @IBOutlet private weak var _blackLevelTextField     : NSTextField!
  @IBOutlet private weak var _lineDurationSlider      : NSSlider!
  @IBOutlet private weak var _lineDurationTextField   : NSTextField!

  @IBOutlet private weak var _autoBlackCheckbox       : NSButton!

  @IBOutlet private weak var _gradientPopUp           : NSPopUpButton!
  
  private var _panafallButtonVC                       : PanafallButtonViewController {
    return representedObject as! PanafallButtonViewController }
  private var _panadapter                             : Panadapter? {
    return _panafallButtonVC.panadapter }
  private var _waterfall                              : Waterfall? {
    return _panafallButtonVC.waterfall }

  private var _observations                           = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    _gradientPopUp.addItems(withTitles: _panafallButtonVC.gradientNames)
    
    // start observing
    addObservations()
  }
  
  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    return true
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Gradient popup
  ///
  /// - Parameter sender:         the popup
  ///
  @IBAction func gradientPopUp(_ sender: NSPopUpButton) {
    
    _waterfall?.gradientIndex = sender.indexOfSelectedItem
  }
  /// Respond to the sliders
  ///
  /// - Parameter sender:         the slider
  ///
  @IBAction func sliders(_ sender: NSSlider) {

    switch sender.identifier!.rawValue {
    case "average":
      _panadapter?.average = sender.integerValue
    case "frames":
      _panadapter?.fps = sender.integerValue
    case "fill":
      Defaults[.spectrumFillLevel] = sender.integerValue
    case "colorGain":
      _waterfall?.colorGain = sender.integerValue
    case "blackLevel":
      _waterfall?.blackLevel = sender.integerValue
    case "lineDuration":
      _waterfall?.lineDuration = sender.integerValue
    default:
      fatalError()
    }
  }
  /// Respond to the checkBoxes
  ///
  /// - Parameter sender:         the slider
  ///
  @IBAction func checkBoxes(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "weightedAverage":
      _panadapter?.weightedAverageEnabled = sender.boolState
    case "autoBlack":
      _waterfall?.autoBlackEnabled = sender.boolState
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
      _panadapter!.observe(\.average, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _panadapter!.observe(\.fps, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _panadapter!.observe(\.weightedAverageEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      
      _waterfall!.observe(\.colorGain, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _waterfall!.observe(\.blackLevel, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _waterfall!.observe(\.lineDuration, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _waterfall!.observe(\.autoBlackEnabled, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      _waterfall!.observe(\.gradientIndex, options: [.initial, .new], changeHandler: changeHandler(_:_:))
    ]
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the object being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ object: Any, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in
      
      if let panadapter = object as? Panadapter {
        self._averageSlider.integerValue = panadapter.average
        self._averageTextField.integerValue = panadapter.average
        
        self._framesSlider.integerValue = panadapter.fps
        self._framesTextField.integerValue = panadapter.fps
        
        self._framesSlider.integerValue = panadapter.fps
        self._framesTextField.integerValue = panadapter.fps

        self._fillSlider.integerValue = Defaults[.spectrumFillLevel]
        self._fillTextField.integerValue = Defaults[.spectrumFillLevel]
        
        self._weightedAverageCheckbox.boolState = panadapter.weightedAverageEnabled

      } else if let waterfall = object as? Waterfall {
        
        self._colorGainSlider.integerValue = waterfall.colorGain
        self._colorGainTextField.integerValue = waterfall.colorGain
        
        self._blackLevelSlider.integerValue = waterfall.blackLevel
        self._blackLevelTextField.integerValue = waterfall.blackLevel
        
        self._lineDurationSlider.integerValue = waterfall.lineDuration
        self._lineDurationTextField.integerValue = waterfall.lineDuration

        self._autoBlackCheckbox.boolState = waterfall.autoBlackEnabled
        
        self._gradientPopUp.selectItem(at: waterfall.gradientIndex)
      }
    }
  }
}

