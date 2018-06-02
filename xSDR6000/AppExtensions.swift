//
//  ApExtensions.swift
//  xSDR6000
//
//  Created by Douglas Adams on 9/22/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults
import simd

typealias NC = NotificationCenter

// ----------------------------------------------------------------------------
// MARK: - EXTENSIONS

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
  static let quickMode0                   = DefaultsKey<String>("quickMode0")
  static let quickMode1                   = DefaultsKey<String>("quickMode1")
  static let quickMode2                   = DefaultsKey<String>("quickMode2")
  static let quickMode3                   = DefaultsKey<String>("quickMode3")
  
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

extension  UserDefaults {
  
  // alternate access to allow KVO observation
  
  @objc dynamic var bandMarker : NSColor {
    get { return Defaults[.bandMarker] }
    set { Defaults[.bandMarker] = newValue } }
  
  @objc dynamic var dbLegend : NSColor {
    get { return Defaults[.dbLegend] }
    set { Defaults[.dbLegend] = newValue } }
  
  @objc dynamic var dbLegendSpacing : String {
    get { return Defaults[.dbLegendSpacing] }
    set { Defaults[.dbLegendSpacing] = newValue } }
  
  @objc dynamic var fillLevel : Int {
    get { return Defaults[.fillLevel] }
    set { Defaults[.fillLevel] = newValue } }
  
  @objc dynamic var frequencyLegend : NSColor {
    get { return Defaults[.frequencyLegend] }
    set { Defaults[.frequencyLegend] = newValue } }
  
  @objc dynamic var gridLines : NSColor {
    get { return Defaults[.gridLines] }
    set { Defaults[.gridLines] = newValue } }
  
  @objc dynamic var gridLinesDashed : Bool {
    get { return Defaults[.gridLinesDashed] }
    set { Defaults[.gridLinesDashed] = newValue } }
  
  @objc dynamic var gridLineWidth : String {
    get { return Defaults[.gridLineWidth] }
    set { Defaults[.gridLineWidth] = newValue } }
  
  @objc dynamic var sliceActive : NSColor {
    get { return Defaults[.sliceActive] }
    set { Defaults[.sliceActive] = newValue } }
  
  @objc dynamic var showMarkers : Bool {
    get { return Defaults[.showMarkers] }
    set { Defaults[.showMarkers] = newValue } }
  
  @objc dynamic var sliceFilter : NSColor {
    get { return Defaults[.sliceFilter] }
    set { Defaults[.sliceFilter] = newValue } }
  
  @objc dynamic var sliceInactive : NSColor {
    get { return Defaults[.sliceInactive] }
    set { Defaults[.sliceInactive] = newValue } }
  
  @objc dynamic var spectrum : NSColor {
    get { return Defaults[.spectrum] }
    set { Defaults[.spectrum] = newValue } }
  
  @objc dynamic var spectrumBackground : NSColor {
    get { return Defaults[.spectrumBackground] }
    set { Defaults[.spectrumBackground] = newValue } }
  
  @objc dynamic var tnfActive : NSColor {
    get { return Defaults[.tnfActive] }
    set { Defaults[.tnfActive] = newValue } }
  
  @objc dynamic var tnfInactive : NSColor {
    get { return Defaults[.tnfInactive] }
    set { Defaults[.tnfInactive] = newValue } }
  
}

extension NSBezierPath {
  
  /// Draw a Horizontal line
  ///
  /// - Parameters:
  ///   - y:            y-position of the line
  ///   - x1:           starting x-position
  ///   - x2:           ending x-position
  ///
  func hLine(at y:CGFloat, fromX x1:CGFloat, toX x2:CGFloat) {
    
    move( to: NSMakePoint( x1, y ) )
    line( to: NSMakePoint( x2, y ) )
  }
  /// Draw a Vertical line
  ///
  /// - Parameters:
  ///   - x:            x-position of the line
  ///   - y1:           starting y-position
  ///   - y2:           ending y-position
  ///
  func vLine(at x:CGFloat, fromY y1:CGFloat, toY y2:CGFloat) {
    
    move( to: NSMakePoint( x, y1) )
    line( to: NSMakePoint( x, y2 ) )
  }
  /// Fill a Rectangle
  ///
  /// - Parameters:
  ///   - rect:           the rect
  ///   - color:          the fill color
  ///
  func fillRect( _ rect:NSRect, withColor color:NSColor, andAlpha alpha:CGFloat = 1) {
    
    // fill the rectangle with the requested color and alpha
    color.withAlphaComponent(alpha).set()
    appendRect( rect )
    fill()
  }
  /// Draw a triangle
  ///
  ///
  /// - Parameters:
  ///   - center:         x-posiion of the triangle's center
  ///   - topWidth:       width of the triangle
  ///   - triangleHeight: height of the triangle
  ///   - topPosition:    y-position of the top of the triangle
  ///
  func drawTriangle(at center:CGFloat, topWidth:CGFloat, triangleHeight:CGFloat, topPosition:CGFloat) {
    
    move(to: NSPoint(x: center - (topWidth/2), y: topPosition))
    line(to: NSPoint(x: center + (topWidth/2), y: topPosition))
    line(to: NSPoint(x: center, y: topPosition - triangleHeight))
    line(to: NSPoint(x: center - (topWidth/2), y: topPosition))
    fill()
  }
  /// Draw an Oval inside a Rectangle
  ///
  /// - Parameters:
  ///   - rect:           the rect
  ///   - color:          the color
  ///   - alpha:          the alpha value
  ///
  func drawCircle(in rect: NSRect, color:NSColor, andAlpha alpha:CGFloat = 1) {
    
    appendOval(in: rect)
    color.withAlphaComponent(alpha).set()
    fill()
  }
  /// Draw a Circle
  ///
  /// - Parameters:
  ///   - point:          the center of the circle
  ///   - radius:         the radius of the circle
  ///
  func drawCircle(at point: NSPoint, radius: CGFloat) {
    
    let rect = NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
    appendOval(in: rect)
  }
  /// Draw an X
  ///
  /// - Parameters:
  ///   - point:          the center of the X
  ///   - halfWidth:      the half width of the X
  ///
  func drawX(at point:NSPoint, halfWidth: CGFloat) {
    
    move(to: NSPoint(x: point.x - halfWidth, y: point.y + halfWidth))
    line(to: NSPoint(x: point.x + halfWidth, y: point.y - halfWidth))
    move(to: NSPoint(x: point.x + halfWidth, y: point.y + halfWidth))
    line(to: NSPoint(x: point.x - halfWidth, y: point.y - halfWidth))
  }
  /// Crosshatch an area
  ///
  /// - Parameters:
  ///   - rect:           the rect
  ///   - color:          a color
  ///   - depth:          an integer ( 1, 2 or 3)
  ///   - linewidth:      width of the crosshatch lines
  ///   - multiplier:     lines per depth
  ///
  func crosshatch(_ rect: NSRect, color: NSColor, depth: Int, twoWay: Bool = false, linewidth: CGFloat = 1, multiplier: Int = 5) {
    
    if depth == 1 || depth > 3 { return }
    
    // calculate the number of lines to draw
    let numberOfLines = depth * multiplier * (depth == 2 ? 1 : 2)
    
    // calculate the line increment
    let incr: CGFloat = rect.size.height / CGFloat(numberOfLines)
    
    // set color and line width
    color.set()
    lineWidth = linewidth
    
    // draw the crosshatch
    for i in 0..<numberOfLines {
      move( to: NSMakePoint( rect.origin.x, CGFloat(i) * incr))
      line(to: NSMakePoint(rect.origin.x + rect.size.width, CGFloat(i+1) * incr))
    }
    if twoWay {
      // draw the opposite crosshatch
      for i in 0..<numberOfLines {
        move( to: NSMakePoint( rect.origin.x + rect.size.width, CGFloat(i) * incr))
        line(to: NSMakePoint(rect.origin.x, CGFloat(i+1) * incr))
      }
    }
  }
  /// Stroke and then Remove all points
  ///
  func strokeRemove() {
    stroke()
    removeAllPoints()
  }
}

extension NSGradient {
  
  // return a "basic" Gradient
  static var basic: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 0, green: 0, blue: 1, alpha: 1),                     // blue
        NSColor(red: 0, green: 1, blue: 1, alpha: 1),                     // cyan
        NSColor(red: 0, green: 1, blue: 0, alpha: 1),                     // green
        NSColor(red: 1, green: 1, blue: 0, alpha: 1),                     // yellow
        NSColor(red: 1, green: 0, blue: 0, alpha: 1),                     // red
        NSColor(red: 1, green: 1, blue: 1, alpha: 1)                      // white
      ]
      let locations: Array<CGFloat> = [ 0.0, 0.15, 0.25, 0.35, 0.55, 0.90, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
  
  // return a "dark" Gradient
  static var dark: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 0, green: 0, blue: 1, alpha: 1),                     // blue
        NSColor(red: 0, green: 1, blue: 0, alpha: 1),                     // green
        NSColor(red: 1, green: 0, blue: 0, alpha: 1),                     // red
        NSColor(red: 1, green: 0.71, blue: 0.76, alpha: 1)                // light pink
      ]
      let locations: Array<CGFloat> = [ 0.0, 0.65, 0.90, 0.95, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
  
  // return a "deuteranopia" Gradient
  static var deuteranopia: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 0.03, green: 0.23, blue: 0.42, alpha: 1),            // dark blue
        NSColor(red: 0.52, green: 0.63, blue: 0.84, alpha: 1),            // light blue
        NSColor(red: 0.65, green: 0.59, blue: 0.45, alpha: 1),            // dark yellow
        NSColor(red: 1, green: 1, blue: 0, alpha: 1),                     // yellow
        NSColor(red: 1, green: 1, blue: 0, alpha: 1),                     // yellow
        NSColor(red: 1, green: 1, blue: 1, alpha: 1)                      // white
      ]
      let locations: Array<CGFloat> = [ 0.0, 0.15, 0.50, 0.65, 0.75, 0.95, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
  
  // return a "grayscale" Gradient
  static var grayscale: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 1, green: 1, blue: 1, alpha: 1)                      // white
      ]
      let locations: Array<CGFloat> = [ 0.0, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
  
  // return a "purple" Gradient
  static var purple: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 0, green: 0, blue: 1, alpha: 1),                     // blue
        NSColor(red: 0, green: 1, blue: 0, alpha: 1),                     // green
        NSColor(red: 1, green: 1, blue: 0, alpha: 1),                     // yellow
        NSColor(red: 1, green: 0, blue: 0, alpha: 1),                     // red
        NSColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),                 // purple
        NSColor(red: 1, green: 1, blue: 1, alpha: 1)                      // white
      ]
      let locations: Array<CGFloat> = [ 0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
  
  // return a "tritanopia" Gradient
  static var tritanopia: NSGradient {
    get {
      let colors = [
        NSColor(red: 0, green: 0, blue: 0, alpha: 1),                     // black
        NSColor(red: 0, green: 0.27, blue: 0.32, alpha: 1),               // dark teal
        NSColor(red: 0.42, green: 0.73, blue: 0.84, alpha: 1),            // light blue
        NSColor(red: 0.29, green: 0.03, blue: 0.09, alpha: 1),            // dark red
        NSColor(red: 1, green: 0, blue: 0, alpha: 1),                     // red
        NSColor(red: 0.84, green: 0.47, blue: 0.52, alpha: 1),            // light red
        NSColor(red: 1, green: 1, blue: 1, alpha: 1)                      // white
      ]
      let locations: Array<CGFloat> = [ 0.0, 0.15, 0.25, 0.45, 0.90, 0.95, 1.0 ]
      return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)!
    }
  }
}

extension NSColor {
  
  // return a float4 version of an rgba NSColor
  var float4Color: float4 { return float4( Float(self.redComponent),
                                           Float(self.greenComponent),
                                           Float(self.blueComponent),
                                           Float(self.alphaComponent))
  }
  // return a bgr8Unorm version of an rgba NSColor
  var bgra8Unorm: UInt32 {
    
    // capture the component values (assumes that the Blue & Red are swapped)
    //      see the Note at the top of this class
    let alpha = UInt32( UInt8( self.alphaComponent * CGFloat(UInt8.max) ) ) << 24
    let red = UInt32( UInt8( self.redComponent * CGFloat(UInt8.max) ) ) << 16
    let green = UInt32( UInt8( self.greenComponent * CGFloat(UInt8.max) ) ) << 8
    let blue = UInt32( UInt8( self.blueComponent * CGFloat(UInt8.max) ) )
    
    // return the UInt32 (in bgra format)
    return alpha + red + green + blue
  }
}

// ----------------------------------------------------------------------------
// MARK: - TOP-LEVEL FUNCTIONS

/// Find versions for this app and the specified framework
///
func versionInfo(framework: String) -> (String, String) {
  let kVersionKey             = "CFBundleShortVersionString"  // CF constants
  let kBuildKey               = "CFBundleVersion"
  
  // get the version of the framework
  let frameworkBundle = Bundle(identifier: framework)!
  var version = frameworkBundle.object(forInfoDictionaryKey: kVersionKey)!
  var build = frameworkBundle.object(forInfoDictionaryKey: kBuildKey)!
  let frameworkVersion = "\(version).\(build)"
  
  // get the version of this app
  version = Bundle.main.object(forInfoDictionaryKey: kVersionKey)!
  build = Bundle.main.object(forInfoDictionaryKey: kBuildKey)!
  let appVersion = "\(version).\(build)"
  
  return (frameworkVersion, appVersion)
}

/// Setup & Register User Defaults from a file
///
/// - Parameter file:         a file name (w/wo extension)
///
func defaults(from file: String) {
  var fileURL : URL? = nil
  
  // get the name & extension
  let parts = file.split(separator: ".")
  
  // exit if invalid
  guard parts.count != 0 else {return }
  
  if parts.count >= 2 {
    
    // name & extension
    fileURL = Bundle.main.url(forResource: String(parts[0]), withExtension: String(parts[1]))
    
  } else if parts.count == 1 {
    
    // name only
    fileURL = Bundle.main.url(forResource: String(parts[0]), withExtension: "")
  }
  
  if let fileURL = fileURL {
    // load the contents
    let myDefaults = NSDictionary(contentsOf: fileURL)!
    
    // register the defaults
    UserDefaults.standard.register(defaults: myDefaults as! Dictionary<String, Any>)
  }
}

