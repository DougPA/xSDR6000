//
//  ColorsPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/8/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class ColorsPrefsViewController: NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _spectrumColor           : NSColorWell!
  @IBOutlet private weak var _frequencyLegendColor    : NSColorWell!
  @IBOutlet private weak var _dbLegendColor           : NSColorWell!
  @IBOutlet private weak var _gridLineColor           : NSColorWell!
  @IBOutlet private weak var _spectrumBackgroundColor : NSColorWell!
  @IBOutlet private weak var _tnfActiveColor          : NSColorWell!
  @IBOutlet private weak var _tnfInactiveColor        : NSColorWell!
  @IBOutlet private weak var _sliceActiveColor        : NSColorWell!
  @IBOutlet private weak var _sliceInactiveColor      : NSColorWell!
  @IBOutlet private weak var _sliceFilterColor             : NSColorWell!
  @IBOutlet private weak var _markerColor             : NSColorWell!
  @IBOutlet private weak var _markerSegmentColor        : NSColorWell!
  @IBOutlet private weak var _markerEdgeColor           : NSColorWell!
  
  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
//    // set the background color of the Flag
//    view.layer?.backgroundColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor

    // start observing
    addObservations()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the colorwells
  ///
  /// - Parameter sender:         the colorwell
  ///
 @IBAction func colors(_ sender: NSColorWell) {
  
    switch sender.identifier!.rawValue {
    case "spectrum":
     Defaults[.spectrum] = sender.color
    case "frequencyLegend":
      Defaults[.frequencyLegend] = sender.color
    case "dbLegend":
      Defaults[.dbLegend] = sender.color
    case "gridLine":
      Defaults[.gridLine] = sender.color
    case "spectrumBackground":
      Defaults[.spectrumBackground] = sender.color
    case "tnfActive":
      Defaults[.tnfActive] = sender.color
    case "tnfInactive":
      Defaults[.tnfInactive] = sender.color
    case "sliceActive":
      Defaults[.sliceActive] = sender.color
    case "sliceInactive":
      Defaults[.sliceInactive] = sender.color
    case "sliceFilter":
      Defaults[.sliceFilter] = sender.color
    case "marker":
      Defaults[.marker] = sender.color
    case "markerSegment":
      Defaults[.markerSegment] = sender.color
    case "markerEdge":
      Defaults[.markerEdge] = sender.color
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
      Defaults.observe(\.spectrum, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.frequencyLegend, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.dbLegend, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.gridLine, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.spectrumBackground, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.tnfActive, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.tnfInactive, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.sliceActive, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.sliceInactive, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.sliceFilter, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.marker, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.markerSegment, options: [.initial], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.markerEdge, options: [.initial], changeHandler: changeHandler(_:_:))
    ]
  }
  /// Process observations
  ///
  /// - Parameters:
  ///   - slice:                    the panadapter being observed
  ///   - change:                   the change
  ///
  private func changeHandler(_ defaults: Any, _ change: Any) {

    DispatchQueue.main.async { [weak self] in
      self?._spectrumColor.color = Defaults[.spectrum]
      self?._frequencyLegendColor.color = Defaults[.frequencyLegend]
      self?._dbLegendColor.color = Defaults[.dbLegend]
      self?._gridLineColor.color = Defaults[.gridLine]
      self?._spectrumBackgroundColor.color = Defaults[.spectrumBackground]
      self?._tnfActiveColor.color = Defaults[.tnfActive]
      self?._tnfInactiveColor.color = Defaults[.tnfInactive]
      self?._sliceActiveColor.color = Defaults[.sliceActive]
      self?._sliceInactiveColor.color = Defaults[.sliceInactive]
      self?._sliceFilterColor.color = Defaults[.sliceFilter]
      self?._markerColor.color = Defaults[.marker]
      self?._markerSegmentColor.color = Defaults[.markerSegment]
      self?._markerEdgeColor.color = Defaults[.markerEdge]
    }
  }
}
