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

// ----------------------------------------------------------------------------
// MARK: - SwiftyUserDefaults

extension UserDefaults {
  
  subscript(key: DefaultsKey<NSColor>) -> NSColor {
    get { return unarchive(key)! }
    set { archive(key, newValue) }
  }
  
//  public subscript(key: DefaultsKey<CGFloat>) -> CGFloat {
//    get { return CGFloat(numberForKey(key._key)?.doubleValue ?? 0.0) }
//    set { set(key, Double(newValue)) }
//  }
}

extension DefaultsKeys {
  
  // Radio level info
  static let cwxViewOpen                  = DefaultsKey<Bool>("cwxViewOpen")
  static let defaultRadio                 = DefaultsKey<[String: Any]>("defaultRadio")
  static let eqRxSelected                 = DefaultsKey<Bool>("eqRxSelected")
  static let fullDuplexEnabled            = DefaultsKey<Bool>("fullDuplexEnabled")
  static let lowBandwidthEnabled          = DefaultsKey<Bool>("lowBandwidthEnabled")
  static let macAudioEnabled              = DefaultsKey<Bool>("macAudioEnabled")
  static let markersEnabled               = DefaultsKey<Bool>("markersEnabled")
  static let quickMode0                   = DefaultsKey<String>("quickMode0")
  static let quickMode1                   = DefaultsKey<String>("quickMode1")
  static let quickMode2                   = DefaultsKey<String>("quickMode2")
  static let quickMode3                   = DefaultsKey<String>("quickMode3")
  static let radioModel                   = DefaultsKey<String>("radioModel")
  static let remoteViewOpen               = DefaultsKey<Bool>("remoteViewOpen")
  static let sideViewOpen                 = DefaultsKey<Bool>("sideViewOpen")
  static let smartLinkAuth0Email          = DefaultsKey<String>("smartLinkAuth0Email")
  static let smartLinkToken               = DefaultsKey<String?>("smartLinkToken")
  static let smartLinkTokenExpiry         = DefaultsKey<Date?>("smartLinkTokenExpiry")
  static let tnfsEnabled                  = DefaultsKey<Bool>("tnfsEnabled")
  static let spectrumFillLevel            = DefaultsKey<Int>("spectrumFillLevel")
  static let spectrumIsFilled             = DefaultsKey<Bool>("spectrumIsFilled")
  static let versionApi                   = DefaultsKey<String>("versionApi")
  static let versionGui                   = DefaultsKey<String>("versionGui")
  static let versionRadio                 = DefaultsKey<String>("versionRadio")

  // Colors common to all Panafalls
  static let dbLegend                     = DefaultsKey<NSColor>("dbLegend")
  static let frequencyLegend              = DefaultsKey<NSColor>("frequencyLegend")
  static let gridLine                     = DefaultsKey<NSColor>("gridLine")
  static let marker                       = DefaultsKey<NSColor>("marker")
  static let markerEdge                   = DefaultsKey<NSColor>("markerEdge")
  static let markerSegment                = DefaultsKey<NSColor>("markerSegment")
  static let sliceActive                  = DefaultsKey<NSColor>("sliceActive")
  static let sliceFilter                  = DefaultsKey<NSColor>("sliceFilter")
  static let sliceInactive                = DefaultsKey<NSColor>("sliceInactive")
  static let spectrum                     = DefaultsKey<NSColor>("spectrum")
  static let spectrumBackground           = DefaultsKey<NSColor>("spectrumBackground")
  static let spectrumFill                 = DefaultsKey<NSColor>("spectrumFill")
  static let tnfActive                    = DefaultsKey<NSColor>("tnfActive")
  static let tnfInactive                  = DefaultsKey<NSColor>("tnfInactive")
  
  // Settings common to all Panafalls
  static let dbLegendSpacing              = DefaultsKey<String>("dbLegendSpacing")
  static let dbLegendSpacings             = DefaultsKey<[String]>("dbLegendSpacings")
  static let timeLegendSpacing            = DefaultsKey<String>("timeLegendSpacing")
  static let timeLegendSpacings           = DefaultsKey<[String]>("timeLegendSpacings")
}

extension  UserDefaults {
  
  // alternate access to allow KVO observation
  
  @objc dynamic var dbLegend : NSColor {
    get { return Defaults[.dbLegend] }
    set { Defaults[.dbLegend] = newValue } }
  
  @objc dynamic var dbLegendSpacing : String {
    get { return Defaults[.dbLegendSpacing] }
    set { Defaults[.dbLegendSpacing] = newValue } }
  
  @objc dynamic var cwxViewOpen : Bool {
    get { return Defaults[.cwxViewOpen] }
    set { Defaults[.cwxViewOpen] = newValue } }
  
  @objc dynamic var frequencyLegend : NSColor {
    get { return Defaults[.frequencyLegend] }
    set { Defaults[.frequencyLegend] = newValue } }
  
  @objc dynamic var fullDuplexEnabled : Bool {
    get { return Defaults[.fullDuplexEnabled] }
    set { Defaults[.fullDuplexEnabled] = newValue } }
  
  @objc dynamic var gridLine : NSColor {
    get { return Defaults[.gridLine] }
    set { Defaults[.gridLine] = newValue } }
  
  @objc dynamic var marker : NSColor {
    get { return Defaults[.marker] }
    set { Defaults[.marker] = newValue } }
  
  @objc dynamic var markerSegment : NSColor {
    get { return Defaults[.markerSegment] }
    set { Defaults[.markerSegment] = newValue } }
  
  @objc dynamic var markerEdge : NSColor {
    get { return Defaults[.markerEdge] }
    set { Defaults[.markerEdge] = newValue } }
  
  @objc dynamic var markersEnabled : Bool {
    get { return Defaults[.markersEnabled] }
    set { Defaults[.markersEnabled] = newValue } }
  
  @objc dynamic var sliceActive : NSColor {
    get { return Defaults[.sliceActive] }
    set { Defaults[.sliceActive] = newValue } }
  
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
  
  @objc dynamic var spectrumFillLevel : Int {
    get { return Defaults[.spectrumFillLevel] }
    set { Defaults[.spectrumFillLevel] = newValue } }
  
  @objc dynamic var tnfActive : NSColor {
    get { return Defaults[.tnfActive] }
    set { Defaults[.tnfActive] = newValue } }
  
  @objc dynamic var tnfInactive : NSColor {
    get { return Defaults[.tnfInactive] }
    set { Defaults[.tnfInactive] = newValue } }

  @objc dynamic var tnfsEnabled : Bool {
    get { return Defaults[.tnfsEnabled] }
    set { Defaults[.tnfsEnabled] = newValue } }
  
  @objc dynamic var versionApi : String {
    get { return Defaults[.versionApi] }
    set { Defaults[.versionApi] = newValue } }
  
  @objc dynamic var versionGui : String {
    get { return Defaults[.versionGui] }
    set { Defaults[.versionGui] = newValue } }

  @objc dynamic var versionRadio : String {
    get { return Defaults[.versionRadio] }
    set { Defaults[.versionRadio] = newValue } }
}

// ----------------------------------------------------------------------------
// MARK: - Bool

extension Bool {

  var state : NSControl.StateValue {
    return self == true ? NSControl.StateValue.on : NSControl.StateValue.off
  }
}

// ----------------------------------------------------------------------------
// MARK: - NSButton

extension NSButton {
  var boolState : Bool {
    get { return self.state == NSControl.StateValue.on ? true : false }
    set { self.state = (newValue == true ? NSControl.StateValue.on : NSControl.StateValue.off) }
  }
}

// ----------------------------------------------------------------------------
// MARK: - FileManager

extension FileManager {
  
  /// Get / create the Application Support folder
  ///
  static var appFolder : URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask )
    let appFolderUrl = urls.first!.appendingPathComponent( Bundle.main.bundleIdentifier! )
    
    // does the folder exist?
    if !fileManager.fileExists( atPath: appFolderUrl.path ) {
      
      // NO, create it
      do {
        try fileManager.createDirectory( at: appFolderUrl, withIntermediateDirectories: false, attributes: nil)
      } catch let error as NSError {
        fatalError("Error creating App Support folder: \(error.localizedDescription)")
      }
    }
    return appFolderUrl
  }
}

// ----------------------------------------------------------------------------
// MARK: - NSBezierPath

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

// ----------------------------------------------------------------------------
// MARK: - NSGradient

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

// ----------------------------------------------------------------------------
// MARK: - NSColor

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
  // return a Metal Clear Color version of an NSColor
  var metalClearColor: MTLClearColor {
    return MTLClearColor(red: Double(self.redComponent),
                         green: Double(self.greenComponent),
                         blue: Double(self.blueComponent),
                         alpha: Double(self.alphaComponent) )
  }
}

// ----------------------------------------------------------------------------
// MARK: - String

extension String {
  
  var numbers: String {
    return String(describing: filter { String($0).rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789")) != nil })
  }
}

// ----------------------------------------------------------------------------
// MARK: - Float

extension Float {
  
  // return the Power value of a Dbm (1 watt) value
  var powerFromDbm: Float {
    return Float( pow( Double(10.0),Double( (self - 30.0)/10.0) ) )
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
  let apiVersion = "\(version).\(build)"
  
  // get the version of this app
  version = Bundle.main.object(forInfoDictionaryKey: kVersionKey)!
  build = Bundle.main.object(forInfoDictionaryKey: kBuildKey)!
  let appVersion = "\(version).\(build)"
  
  return (apiVersion, appVersion)
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

