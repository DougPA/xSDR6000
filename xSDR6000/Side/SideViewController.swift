//
//  SideViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/30/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Side View Controller class implementation
// --------------------------------------------------------------------------------

final class SideViewController              : NSSplitViewController {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _api                          = Api.sharedInstance

  private var _topConstraints               = [NSLayoutConstraint]()

  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.translatesAutoresizingMaskIntoConstraints = false

    view.layer?.backgroundColor = NSColor.lightGray.cgColor
    
//    Swift.print("sideView height = \(view.frame.height)")
    
    let widthConstraint = splitView.widthAnchor.constraint(equalToConstant: 311)
    widthConstraint.identifier = "Side width constraint"
    widthConstraint.isActive = true

    
    sideView("BUTTONS", show: true)
  }

  override func viewDidAppear() {
    
//    Swift.print("sideView height = \(view.frame.height)")

  }
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to one of the Side buttons
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func sideButtons(_ sender: NSButton) {
    
    sideView( sender.identifier!.rawValue, show: sender.boolState )
  }
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Display / Hide a side view
  ///
  /// - Parameters:
  ///   - identifier:     a Storyboard identifier
  ///   - show:           show?
  ///
  private func sideView(_ identifier: String, show: Bool) {
    
    // show or hide?
    if show {
      
      // SHOW, create a view controller
      //      let sbIdentifier = identifier
      //      let vc = _sideStoryboard!.instantiateController(withIdentifier: sbIdentifier ) as! NSViewController
      
      var height : CGFloat = 0
      switch identifier {
      case "BUTTONS":
        height = 37
      case "RX":
        height = 108
      case "TX":
        height = 207
      case "PCW":
        height = 240
      case "PHNE":
        height = 192
      case "EQ":
        height = 170
      default:
        fatalError()
      }
      
      
      let vc = createAndPosition(identifier: identifier, height: height)
      
      
      // add it to the Side View
      var index = 0
      switch identifier {
      case "BUTTONS":
        index = 0
      case "RX":
        index = 1
      case "TX":
        index = 2
      case "PCW":
        index = 3
      case "PHNE":
        index = 4
      case "EQ":
        index = 5
      default:
        fatalError()
      }
      let numberOfViews = children.count
      if index >= numberOfViews {
        insertChild(vc, at: numberOfViews)
        
      } else {
        
        insertChild(vc, at: index)
      }
      
      // position it in the splitView
      adjustConstraints()
      
    } else {
      
      // HIDE, remove it from the Side View
      if let vc = children.first(where: {$0.identifier!.rawValue == identifier} ) {
        vc.removeFromParent()
        
        // position it in the splitView
        adjustConstraints()
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Methods
  
  /// Create a new View & Position it
  ///
  /// - Parameters:
  ///   - identifier:             a Storyboard Identifier
  ///   - height:                 the height
  ///
  private func createAndPosition(identifier: NSStoryboard.SceneIdentifier, height: CGFloat ) -> NSViewController {
    
    // get the Storyboard containing a View1 Controller
    let sb = NSStoryboard(name: "Side", bundle: nil)
    
    // create the View Controller for the identifier
    let vc = sb.instantiateController(withIdentifier: identifier) as? NSViewController
    
    // give it a reference to its Radio object
    vc!.representedObject = _api.radio
    
    // constrain its Height
//    vc!.view.heightAnchor.constraint(equalToConstant: height).isActive = true
//    vc!.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 311).isActive = true
    
    addSplitViewItem(NSSplitViewItem(viewController: vc!))
    
    // position it in the Side view
//    adjustConstraints()
    
    return vc!
  }
  /// Constrain each view to the one above it
  ///
  private func adjustConstraints() {
    
    // for each Side Item
    for (i, item) in splitViewItems.enumerated() {
      
      switch (i, _topConstraints.count) {
      case (0, i):
        // topmost view, constraint not yet created
        _topConstraints.append( item.viewController.view.topAnchor.constraint(equalTo: view.topAnchor) )
        
      case (0, _):
        // topmost view, constraint exists for this index
        _topConstraints[i].isActive = false
        _topConstraints[i] = item.viewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        
      case (_, i):
        // not topmost view, constraint not yet created
        _topConstraints.append( item.viewController.view.topAnchor.constraint(equalTo: splitViewItems[i - 1].viewController.view.bottomAnchor) )
        
      case (_, _):
        // not topmost view, constraint exists for this index
        _topConstraints[i].isActive = false
        _topConstraints[i] = item.viewController.view.topAnchor.constraint(equalTo: splitViewItems[i - 1].viewController.view.bottomAnchor)
      }
      // make the constraint active
      _topConstraints[i].isActive = true
      
      Swift.print("i = \(i), _topConstraints = \(_topConstraints)")
    }
  }

}
