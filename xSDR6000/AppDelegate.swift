//
//  AppDelegate.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/7/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
//import xLib6000
//import SwiftyUserDefaults
//import XCGLogger

let kClientName = "xSDR6000"

@NSApplicationMain
final class AppDelegate                     : NSObject, NSApplicationDelegate {
  
//  // Name of the base Log file
//  static let kLogFile                       = "xSDR6000.log"
  
//  // lazy setup of the XCGLogger
//  let log: XCGLogger = {
//
//    // Create a logger object with no destinations
//    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
//
//    #if DEBUG
//
//      // for DEBUG only
//      // Create a destination for the system console log (via NSLog)
//      let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")
//
//      // Optionally set some configuration options
//      systemDestination.outputLevel = .info
//      systemDestination.showLogIdentifier = false
//      systemDestination.showFunctionName = true
//      systemDestination.showThreadName = false
//      systemDestination.showLevel = true
//      systemDestination.showLineNumber = false
//      systemDestination.showDate = false                              // AppleSystemLogDestination always adds a datetime
//
//      // Add the destination to the logger
//      log.add(destination: systemDestination)
//
//    #endif
//
//    // Create a file log destination
//    let fileDestination = AutoRotatingFileDestination(writeToFile: FileManager.appFolder.appendingPathComponent(AppDelegate.kLogFile), identifier: "advancedLogger.autoRotatingFileDestination")
//
//    // Optionally set some configuration options
//    fileDestination.targetMaxFileSize       = 1_048_576                     // 2^20
//    fileDestination.targetMaxLogFiles       = 5
//    fileDestination.outputLevel             = .info
//    fileDestination.showLogIdentifier       = false
//    fileDestination.showFunctionName        = true
//    fileDestination.showThreadName          = true
//    fileDestination.showLevel               = true
//    fileDestination.showFileName            = true
//    fileDestination.showLineNumber          = true
//    fileDestination.showDate                = true
//
//    // Process this destination in the background
//    fileDestination.logQueue = XCGLogger.logQueue
//
//    // Add the destination to the logger
//    log.add(destination: fileDestination)
//
//
//    // Add basic app info, version info etc, to the start of the logs
//    log.logAppDetails()
//
//    // format the date (only effects the file logging)
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
//    dateFormatter.locale = Locale.current
//    log.dateFormatter = dateFormatter
//
//    return log
//  }()
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - LogHandlerDelegate methods
  
  /// Process log messages
  ///
  /// - Parameters:
  ///   - msg:        a message
  ///   - level:      the severity level of the message
  ///   - function:   the name of the function creating the msg
  ///   - file:       the name of the file containing the function
  ///   - line:       the line number creating the msg
  ///
//  public func msg(_ msg: String, level: MessageLevel, function: StaticString, file: StaticString, line: Int ) -> Void {
//
//    // Log Handler to support XCGLogger
//
//    switch level {
//    case .verbose:
//      log.verbose(msg, functionName: function, fileName: file, lineNumber: line )
//
//    case .debug:
//      log.debug(msg, functionName: function, fileName: file, lineNumber: line)
//
//    case .info:
//      log.info(msg, functionName: function, fileName: file, lineNumber: line)
//
//    case .warning:
//      log.warning(msg, functionName: function, fileName: file, lineNumber: line)
//
//    case .error:
//      log.error(msg, functionName: function, fileName: file, lineNumber: line)
//
//    case .severe:
//      log.severe(msg, functionName: function, fileName: file, lineNumber: line)
//    }
//  }
}


