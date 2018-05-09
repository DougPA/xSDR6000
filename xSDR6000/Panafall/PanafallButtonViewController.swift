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
// MARK: - Panafall Button View Controller class implementation
// --------------------------------------------------------------------------------

final class PanafallButtonViewController    : NSViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var radio: Radio?                         = Api.sharedInstance.radio
  @objc dynamic weak var panadapter         : Panadapter?
  @objc dynamic weak var waterfall          : Waterfall? { return radio!.waterfalls[panadapter!.waterfallId] }
  
  @IBOutlet weak var buttonView             : PanafallButtonView!
  
  // used by bindings in Popovers
  //Panafall
  @objc dynamic var fillLevel: Int {
    get { return Defaults[.fillLevel] }
    set { Defaults[.fillLevel] = newValue } }
  
  // Waterfall
  @objc dynamic var gradientNames: [String]
  { return WaterfallViewController.gradientNames }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private weak var _panafallViewController       : PanafallViewController?
  private weak var _panadapterViewController     : PanadapterViewController?
  private weak var _waterfallViewController      : WaterfallViewController?
  
  private var _center                       : Int {return panadapter!.center }
  private var _bandwidth                    : Int { return panadapter!.bandwidth }
  private var _minDbm                       : CGFloat { return panadapter!.minDbm }
  private var _maxDbm                       : CGFloat { return panadapter!.maxDbm }
  
  // constants
  private let kPanafallEmbed                = "PanafallEmbed"               // Segue names
  private let kBandPopover                  = "BandPopover"
  private let kAntennaPopover               = "AntennaPopover"
  private let kDisplayPopover               = "DisplayPopover"
  private let kDaxPopover                   = "DaxPopover"
  
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
    
    switch segue.identifier!.rawValue {
      
    case kPanafallEmbed:                            // this will always occur first
      
      // pass a copy of the Params
      (segue.destinationController as! NSViewController).representedObject = representedObject
      
      // save a reference to the Panafall view controller
      _panafallViewController = segue.destinationController as? PanafallViewController
      
      // pass the Radio & Panadapter
      _panafallViewController!.radio = radio
      _panafallViewController!.panadapter = panadapter
      
      // give the PanadapterViewController & waterfallViewControllers a copy of Radio & Panadapter
      _panadapterViewController = _panafallViewController!.splitViewItems[kPanadapterSplitViewItem].viewController as? PanadapterViewController
      _waterfallViewController = _panafallViewController!.splitViewItems[kWaterfallSplitViewItem].viewController as? WaterfallViewController
      
      _panadapterViewController!.radio = radio
      _panadapterViewController!.panadapter = panadapter
      
      _waterfallViewController!.radio = radio
      _waterfallViewController!.panadapter = panadapter
      
    case kAntennaPopover, kDisplayPopover, kDaxPopover, kBandPopover:
      
      // pass the Popovers a reference to this controller
      (segue.destinationController as! NSViewController).representedObject = self
      
    default:
      break
    }
  }
  
//  deinit {
//    Swift.print("PanafallButtonViewController - deinit")
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Zoom + (decrease bandwidth)
  ///
  /// - Parameter sender: the sender
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
  /// - Parameter sender: the sender
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
  /// Close this Panafall
  ///
  /// - Parameter sender: the sender
  ///
  @IBAction func close(_ sender: NSButton) {
    
    buttonView.removeTrackingArea()
    
    // tell the Radio to remove this Panafall
    panadapter!.remove()
  }
  /// Create a new Slice (if possible)
  ///
  /// - Parameter sender: the sender
  ///
  @IBAction func rx(_ sender: NSButton) {
    
    // tell the Radio (hardware) to add a Slice on this Panadapter
    xLib6000.Slice.create(panadapter: panadapter!)
  }
  /// Create a new Tnf
  ///
  /// - Parameter sender: the sender
  ///
  @IBAction func tnf(_ sender: NSButton) {
    
    // tell the Radio (hardware) to add a Tnf on this Panadapter
    Tnf.create(frequency: "")
  }
}
