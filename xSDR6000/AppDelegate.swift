//
//  AppDelegate.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/7/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa

let kClientName = "xSDR6000"

@NSApplicationMain
final class AppDelegate                     : NSObject, NSApplicationDelegate {
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}


