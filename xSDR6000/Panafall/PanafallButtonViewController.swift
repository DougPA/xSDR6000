//
//  PanafallButtonViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 6/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults

// --------------------------------------------------------------------------------
//  Created by PanafallsViewController
//  Removed by WaterfallViewController
//
//  **** Notifications received ****
//      None
//
//  **** Action Methods ****
//      Zoom plus -> reduce bandwidth
//      Zoom minus -> increase bandwidth
//      Zoom segment -> bandwidth = segment
//      Zoom band -> bandwidth = band
//      Remove panafall
//      Slice add
//      Tnf add
//
//  **** Observations ****
//      None
//
//  **** View Bindings ****
//      None
//
// --------------------------------------------------------------------------------

// --------------------------------------------------------------------------------
// MARK: - Panafall Button View Controller class implementation
// --------------------------------------------------------------------------------

final class PanafallButtonViewController    : NSViewController {

  static let kTimeout                       = 10
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  // KVO-properties for popovers
  @objc dynamic weak var panadapter         : Panadapter?
  @objc dynamic weak var waterfall          : Waterfall?
  @objc dynamic var fillLevel               : Int {
    get { return Defaults[.spectrumFillLevel] }
    set { Defaults[.spectrumFillLevel] = newValue } }
  @objc dynamic var gradientNames           : [String] {
    return WaterfallViewController.gradientNames }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  @IBOutlet private weak var buttonView             : PanafallButtonView!
  
  private var _bandwidth                    : Int { return panadapter!.bandwidth }
  private var _popover                      : NSPopover?
  
  private let kPanafallEmbedIdentifier      = "PanafallEmbed"
  private let kBandPopoverIdentifier        = "BandPopover"
  private let kBandPopoverNewIdentifier     = "BandPopoverNew"
  private let kAntennaPopoverIdentifier     = "AntennaPopover"
  private let kDisplayPopoverIdentifier     = "DisplayPopover"
  private let kDaxPopoverIdentifier         = "DaxPopover"

  private let kPanadapterSplitViewItem      = 0
  private let kWaterfallSplitViewItem       = 1
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  /// Prepare to execute a Segue
  ///
  /// - Parameters:
  ///   - segue: a Segue instance
  ///   - sender: the sender
  ///
  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    
    _popover = segue.destinationController as? NSPopover
    
    switch segue.identifier! {
      
    case kPanafallEmbedIdentifier:                            // this will always occur first
      
      // pass a copy of the Params
      (segue.destinationController as! NSViewController).representedObject = representedObject
      
      // save a reference to the Panafall view controller
      let panafallViewController = segue.destinationController as? PanafallViewController
      
      // pass needed parameters
      panafallViewController!.configure(panadapter: panadapter)
      
      // save a reference to the panadapterViewController & waterfallViewController
      let panadapterViewController = panafallViewController!.splitViewItems[kPanadapterSplitViewItem].viewController as? PanadapterViewController
      let waterfallViewController = panafallViewController!.splitViewItems[kWaterfallSplitViewItem].viewController as? WaterfallViewController
      
      // pass needed parameters
      panadapterViewController!.configure(panadapter: panadapter)
      waterfallViewController!.configure(panadapter: panadapter)
      
    case kDisplayPopoverIdentifier:
      
      // pass the Popovers a reference to this controller
      (segue.destinationController as! NSViewController).representedObject = self
      
    case kAntennaPopoverIdentifier, kBandPopoverIdentifier, kBandPopoverNewIdentifier, kDaxPopoverIdentifier:
      
      // pass the Popovers a reference to the panadapter
      (segue.destinationController as! NSViewController).representedObject = panadapter
      
    default:
      break
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Configure needed parameters
  ///
  /// - Parameter panadapter:               a Panadapter reference
  ///
  func configure(panadapter: Panadapter?, waterfall: Waterfall?) {
    self.panadapter = panadapter
    self.waterfall = waterfall
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Zoom + (decrease bandwidth)
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func zoomPlus(_ sender: NSButton) {
    
    // are we near the minimum?
    if _bandwidth / 2 > panadapter!.minBw {
      
      // NO, make the bandwidth half of its current value
      panadapter!.bandwidth = _bandwidth / 2
      
    } else {
      
      // YES, make the bandwidth the minimum value
      panadapter!.bandwidth = panadapter!.minBw
    }
  }
  /// Zoom - (increase the bandwidth)
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func zoomMinus(_ sender: NSButton) {
    // are we near the maximum?
    if _bandwidth * 2 > panadapter!.maxBw {
      
      // YES, make the bandwidth maximum value
      panadapter!.bandwidth = panadapter!.maxBw
      
    } else {
      
      // NO, make the bandwidth twice its current value
      panadapter!.bandwidth = _bandwidth * 2
    }
  }
  /// Zoom to Segment
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func zoomSegment(_ sender: NSButton) {
    panadapter!.segmentZoomEnabled = !panadapter!.segmentZoomEnabled
  }
  /// Zoom to Band
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func zoomBand(_ sender: NSButton) {
    panadapter!.bandZoomEnabled = !panadapter!.bandZoomEnabled
  }
  
  /// Close this Panafall
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func close(_ sender: NSButton) {
    
    buttonView.removeTrackingArea()
    
    // tell the Radio to remove this Panafall
    panadapter!.remove()
  }
  /// Create a new Slice (if possible)
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func rx(_ sender: NSButton) {
    
    // tell the Radio (hardware) to add a Slice on this Panadapter
    xLib6000.Slice.create(panadapter: panadapter!)
  }
  /// Create a new Tnf
  ///
  /// - Parameter sender:           the sender
  ///
  @IBAction func tnf(_ sender: NSButton) {
    
    // tell the Radio (hardware) to add a Tnf on this Panadapter
    Tnf.create(frequency: "")
  }
}
