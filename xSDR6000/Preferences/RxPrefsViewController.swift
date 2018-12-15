//
//  RxPrefsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 12/13/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class RxPrefsViewController: NSViewController {

  @objc public func calibrate() {

    Swift.print("RxPrefsViewController, Calibrate")

    if let radio = Api.sharedInstance.radio { radio.calibrate() }

  }
}
