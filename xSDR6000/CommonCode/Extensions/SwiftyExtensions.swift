//
//  LocalExtensions.swift
//  xAPITester
//
//  Created by Douglas Adams on 12/10/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

// ----------------------------------------------------------------------------
// MARK: - Definitions for SwiftyUserDefaults

extension UserDefaults {
  
  subscript(key: DefaultsKey<NSColor>) -> NSColor {
    get { return unarchive(key)! }
    set { archive(key, newValue) }
  }
  
  public subscript(key: DefaultsKey<CGFloat>) -> CGFloat {
    get { return CGFloat(numberForKey(key._key)?.doubleValue ?? 0.0) }
    set { set(key, Double(newValue)) }
  }
}

extension DefaultsKeys {
  
  // Radio level info
  static let apiFirmwareSupport           = DefaultsKey<String>("apiFirmwareSupport")
  static let apiVersion                   = DefaultsKey<String>("apiVersion")
  static let auth0Email                   = DefaultsKey<String>("auth0Email")
  static let defaultRadioParameters       = DefaultsKey<[String]>("defaultRadioParameters") // obsolete
  static let defaultsDictionary           = DefaultsKey<[String: Any]>("defaultsDictionary")
  static let guiFirmwareSupport           = DefaultsKey<String>("guiFirmwareSupport")
  static let guiVersion                   = DefaultsKey<String>("guiVersion")
  static let logNumber                    = DefaultsKey<Int>("logNumber")
  static let openGLVersion                = DefaultsKey<String>("openGLVersion")
  static let radioFirmwareVersion         = DefaultsKey<String>("radioFirmwareVersion")
  static let radioModel                   = DefaultsKey<String>("radioModel")
  static let remoteRxEnabled              = DefaultsKey<Bool>("remoteRxEnabled")
  static let remoteTxEnabled              = DefaultsKey<Bool>("remoteTxEnabled")
  static let rxEqSelected                 = DefaultsKey<Bool>("rxEqSelected")
  static let saveLogOnExit                = DefaultsKey<Bool>("saveLogOnExit")
  static let showMarkers                  = DefaultsKey<Bool>("showMarkers")
  static let showRemoteTabView            = DefaultsKey<Bool>("showRemoteTabView")
  static let sideOpen                     = DefaultsKey<Bool>("sideOpen")
  static let smartLinkToken               = DefaultsKey<String?>("smartLinkToken")
  static let smartLinkTokenExpiry         = DefaultsKey<Date?>("smartLinkTokenExpiry")
  static let spectrumIsFilled             = DefaultsKey<Bool>("spectrumIsFilled")
  static let spectrumStyle                = DefaultsKey<Int>("spectrumStyle")
  static let toolbar                      = DefaultsKey<NSColor>("toolbar")
  static let useLowBw                     = DefaultsKey<Bool>("useLowBw")
  
  // Colors common to all Panafalls
  static let bandEdge                     = DefaultsKey<NSColor>("bandEdge")
  static let bandMarker                   = DefaultsKey<NSColor>("bandMarker")
  static let buttonsBackground            = DefaultsKey<NSColor>("buttonsBackground")
  static let cwxOpen                      = DefaultsKey<Bool>("cwxOpen")
  static let dbLegend                     = DefaultsKey<NSColor>("dbLegend")
  static let dbLegendBackground           = DefaultsKey<NSColor>("dbLegendBackground")
  static let fillLevel                    = DefaultsKey<Int>("fillLevel")
  static let filterLegend                 = DefaultsKey<NSColor>("filterLegend")
  static let filterLegendBackground       = DefaultsKey<NSColor>("filterLegendBackground")
  static let frequencyLegend              = DefaultsKey<NSColor>("frequencyLegend")
  static let frequencyLegendBackground    = DefaultsKey<NSColor>("frequencyLegendBackground")
  static let gridLines                    = DefaultsKey<NSColor>("gridLines")
  static let segmentEdge                  = DefaultsKey<NSColor>("segmentEdge")
  static let sliceActive                  = DefaultsKey<NSColor>("sliceActive")
  static let sliceFilter                  = DefaultsKey<NSColor>("sliceFilter")
  static let sliceInactive                = DefaultsKey<NSColor>("sliceInactive")
  static let spectrum                     = DefaultsKey<NSColor>("spectrum")
  static let spectrumBackground           = DefaultsKey<NSColor>("spectrumBackground")
  static let spectrumFill                 = DefaultsKey<NSColor>("spectrumFill")
  static let text                         = DefaultsKey<NSColor>("text")
  static let tnfActive                    = DefaultsKey<NSColor>("tnfActive")
  static let tnfInactive                  = DefaultsKey<NSColor>("tnfInactive")
  static let tnfNormal                    = DefaultsKey<NSColor>("tnfNormal")
  static let tnfDeep                      = DefaultsKey<NSColor>("tnfDeep")
  static let tnfVeryDeep                  = DefaultsKey<NSColor>("tnfVeryDeep")
  
  // Settings common to all Panafalls
  static let bandMarkerOpacity            = DefaultsKey<CGFloat>("bandMarkerOpacity")
  static let dbLegendSpacing              = DefaultsKey<String>("dbLegendSpacing")
  static let dbLegendSpacings             = DefaultsKey<[String]>("dbLegendSpacings")
  static let gridLinesDashed              = DefaultsKey<Bool>("gridLinesDashed")
  static let gridLineWidth                = DefaultsKey<String>("gridLineWidth")
  static let gridLinesWidths              = DefaultsKey<[String]>("gridLinesWidths")
  static let sliceFilterOpacity           = DefaultsKey<CGFloat>("sliceFilterOpacity")
  static let timeLegendSpacing            = DefaultsKey<String>("timeLegendSpacing")
  static let timeLegendSpacings           = DefaultsKey<[String]>("timeLegendSpacings")
}

