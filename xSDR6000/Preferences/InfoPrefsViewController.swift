//
//  InfoPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 1/8/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class InfoPrefsViewController: NSViewController {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _versionGuiTextField    : NSTextField!
  @IBOutlet private weak var _versionApiTextField    : NSTextField!

  private var _observations                 = [NSKeyValueObservation]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5).cgColor

    // start observing
    addObservations()
  }
 
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observations of various properties used by the view
  ///
  private func addObservations() {
    
    _observations = [
      Defaults.observe(\.versionApi, options: [.initial, .new], changeHandler: changeHandler(_:_:)),
      Defaults.observe(\.versionGui, options: [.initial, .new], changeHandler: changeHandler(_:_:))
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
      self?._versionGuiTextField.stringValue = Defaults[.versionGui]
      self?._versionApiTextField.stringValue = Defaults[.versionApi]
    }
  }
}
