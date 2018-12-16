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


    if let radio = Api.sharedInstance.radio {
      Swift.print("RxPrefsViewController, Calibrate")
      radio.startCalibration = true
      
    }

  }
}
