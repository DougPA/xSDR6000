//
//  LevelIndicator.swift
//  CustomLevelIndicator
//
//  Created by Douglas Adams on 9/8/18.
//  Copyright © 2018 Douglas Adams. All rights reserved.
//

import Cocoa

public typealias LegendTuple = (tick: Int?, label: String, fudge: CGFloat)

class LevelIndicator: NSView {
  
  public var level                          : CGFloat = 0.0 {
    didSet { needsDisplay = true } }        // force a redraw
  public var peak                           : CGFloat = 0.0 {
    didSet { needsDisplay = true } }        // force a redraw
  public var font                           = NSFont(name: "Monaco", size: 14.0)  
  public var legends: [LegendTuple] = [ (nil, "Level", 0) ]
  

  private var _path                         = NSBezierPath()
  private var _framePath                    = NSBezierPath()

  // layout
  @IBInspectable var _numberOfSegments      : Int = 4
  @IBInspectable var _leftValue             : CGFloat = 0         // left before being flipped
  @IBInspectable var _rightValue            : CGFloat = 100       // right before being flipped
  @IBInspectable var _warningLevel          : CGFloat = 80
  @IBInspectable var _criticalLevel         : CGFloat = 90
  @IBInspectable var _isFlipped             : Bool = false

  // colors
  @IBInspectable var _frameColor            : NSColor = NSColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1.0)
  @IBInspectable var _backgroundColor       : NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
  @IBInspectable var _normalColor           : NSColor = NSColor.systemGreen
  @IBInspectable var _warningColor          : NSColor = NSColor.systemYellow
  @IBInspectable var _criticalColor         : NSColor = NSColor.systemRed
  @IBInspectable var _legendColor           : NSColor = NSColor.white

  // internal
  private var _range                        : CGFloat = 0.0
  private var _warningPercent               : CGFloat = 0.0
  private var _warningPosition              : CGFloat = 0.0
  private var _criticalPercent              : CGFloat = 0.0
  private var _criticalPosition             : CGFloat = 0.0
  private var _transform                    : AffineTransform!

  // font related
  private var _attributes                   = [NSAttributedStringKey:AnyObject]()
  
  // calculated sizes
  private var _heightGraph                  : CGFloat = 0
  private var _heightTopSpace               : CGFloat = 0
  private var _heightFont                   : CGFloat = 0
  private var _heightLine                   : CGFloat = 3.0
  private var _heightInset                  : CGFloat = 0
  private var _heightBar                    : CGFloat = 0
  private var _topLineY                     : CGFloat = 0
  private var _bottomLineY                  : CGFloat = 0
  private var _fontY                        : CGFloat = 0
  private var _barTopY                      : CGFloat = 0
  private var _barBottomY                   : CGFloat = 0

  // constants
  private let kPeakWidth                    : CGFloat = 5
  
//  private let kStandard                     : Int = 0
//  private let kSMeter                       : Int = 1
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)

    assert(frame.height >= 15.0, "Frame height \(frame.height) < 15.0")
  }
  
  override func viewWillDraw() {
    
    // setup the Legend font & size
    _attributes[NSAttributedStringKey.font] = font
    
    // setup the Legend color
    _attributes[NSAttributedStringKey.foregroundColor] = _legendColor
    
    // calculate a typical font height
    _heightFont = "-000".size(withAttributes: _attributes).height

    // calculate sizes
    _heightTopSpace = frame.height * 0.1
    _heightGraph = frame.height - _heightFont - _heightTopSpace
    _heightLine = _heightGraph * 0.1
    _heightInset = _heightLine
    _heightBar = _heightGraph - _heightLine - _heightInset - (2 * _heightLine)
    _barBottomY = _heightInset + _heightLine
    _barTopY = _barBottomY + _heightBar
    
    _fontY = frame.height - _heightFont - _heightTopSpace
    _topLineY = frame.height - _heightFont - _heightTopSpace
    _bottomLineY = 0
    
    // create a transform (if flipped)
    if _isFlipped {
      _transform = AffineTransform(translationByX: frame.width, byY: frame.height - _heightFont - _heightTopSpace)
      _transform.rotate(byDegrees: 180)
    }

    // calculate percents & positions
    _range = _rightValue - _leftValue
    _warningPercent = ((_warningLevel - _leftValue) / _range)
    _warningPosition = _warningPercent * frame.width
    _criticalPercent = ((_criticalLevel - _leftValue) / _range)
    _criticalPosition = _criticalPercent * frame.width
    
    // validate the positions
    if _leftValue < _rightValue {
      assert(_warningLevel - _leftValue <= _criticalLevel - _leftValue, "Invalid layout")
    } else {
      assert(_warningLevel - _leftValue >= _criticalLevel - _leftValue, "Invalid layout")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden Methods
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    drawFrame(dirtyRect)

    setupBar(dirtyRect)

    setupPeak(dirtyRect)

    // draw the Bar & Peak
    _path.strokeRemove()

    drawLegends(legends)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Methods
  
  /// Setup the meter frame
  ///
  /// - Parameter dirtyRect:          LevelIndicator rect
  ///
  fileprivate func drawFrame(_ dirtyRect: NSRect) {
    
    // set Line Width
    _framePath.lineWidth = _heightLine
    
    // create the top & bottom line (critical range)
    _criticalColor.set()
    _framePath.hLine(at: _topLineY, fromX: _criticalPosition, toX: dirtyRect.width)
    _framePath.hLine(at: _bottomLineY, fromX: _criticalPosition, toX: dirtyRect.width)
    
    // Flip if required
    if _isFlipped { _framePath.transform(using: _transform) }
    
    _framePath.strokeRemove()

    // create the top & bottom line (normal & warning range)
    _frameColor.set()
    _framePath.hLine(at: _topLineY, fromX: 0, toX: _criticalPosition)
    _framePath.hLine(at: _bottomLineY, fromX: 0, toX: _criticalPosition)
    
    // Flip if required
    if _isFlipped { _framePath.transform(using: _transform) }
    
    _framePath.strokeRemove()
    
    // create the vertical hash marks
    let segmentWidth = dirtyRect.width / CGFloat(_numberOfSegments)
    var lineColor : NSColor
    var xPosition : CGFloat
    for i in 0..._numberOfSegments {
      xPosition = segmentWidth * CGFloat(i)
      // determine the line color
      switch xPosition {
        
      case _criticalPosition...:
        lineColor = _criticalColor
        
      default:
        lineColor = _frameColor
      }
      // create line with the required color
      lineColor.set()
      
      if xPosition == 0 { xPosition = _heightLine }
      if xPosition == frame.width { xPosition = frame.width - _heightLine }
      _framePath.vLine(at: xPosition, fromY: _barTopY, toY: _barBottomY)
      
      // Flip if required
      if _isFlipped { _framePath.transform(using: _transform) }
      
      _framePath.strokeRemove()
    }
  }
  /// Setup the Bar
  ///
  /// - Parameter dirtyRect:          LevelIndicator rect
  ///
  fileprivate func setupBar(_ dirtyRect: NSRect) {
    
    let levelPercent = ((level - _leftValue) / _range)
    
    _backgroundColor.set()
    
    // create the bar
    var remainingPercent = levelPercent
    switch remainingPercent {
      
    case _criticalPercent...:
      
      // append the critical section
      let width = ((remainingPercent - _criticalPercent) * dirtyRect.width)
      appendSection(at: _criticalPosition, width: width, color: _criticalColor)
      
      remainingPercent = _criticalPercent
      fallthrough
      
    case _warningPercent..._criticalPercent:
      
      // append the warning section
      let width = (remainingPercent - _warningPercent) * dirtyRect.width
      appendSection(at: _warningPosition, width: width, color: _warningColor)
      
      remainingPercent = _warningPercent
      fallthrough
      
    default:
      
      // append the normal section
      let width = remainingPercent * dirtyRect.width
      appendSection(at: 0, width: width, color: _normalColor)
    }
  }
  /// Setup Peak
  ///
  /// - Parameter dirtyRect:          LevelIndicator rect
  ///
  fileprivate func setupPeak(_ dirtyRect: NSRect) {
    
    let peakPercent = ((peak - _leftValue) / _range)
    
    var peakColor: NSColor
    
    // determine the peak color
    switch peakPercent {
      
    case _criticalPercent...:
      peakColor = _criticalColor
      
    case _warningPercent..._criticalPercent:
      peakColor = _warningColor
      
    default:
      peakColor = _normalColor
    }
    
    // append the peak section
    appendSection(at: peakPercent * dirtyRect.width, width: kPeakWidth, color: peakColor)
  }
  /// Create a section & append it
  ///
  /// - Parameters:
  ///   - position:               position of the level
  ///   - width:                  width of the bar
  ///   - color:                  color of the bar
  ///
  private func appendSection(at position: CGFloat, width: CGFloat, color: NSColor) {
    
    // construct its rect
    let rect = NSRect(origin: CGPoint(x: position, y: _barBottomY),
                      size: CGSize(width: width, height: _heightBar))
    // create & append the section
    _path.append( createBar(at: rect, color: color) )
  }
  /// Create a filled rect area
  ///
  /// - Parameters:
  ///   - rect:                   the area
  ///   - color:                  an NSColor
  /// - Returns:                  the filled NSBezierPath
  ///
  private func createBar(at rect: NSRect, color: NSColor) -> NSBezierPath {
    
    // create a path with the specified rect
    let path = NSBezierPath(rect: rect)

    // Flip if required
    if _isFlipped {
      path.transform(using: _transform)
    }
    // fill it with color
    color.setFill()
    path.fill()
    
    return path
  }
  /// Draw a legend at specified vertical bar(s)
  ///
  /// - Parameter legends:        an array of LegendTuple
  ///
  private func drawLegends(_ legends: [LegendTuple]) {

    let segmentWidth = frame.width / CGFloat(_numberOfSegments)
    
    // draw the legends
    for legend in legends {
      // is it a nrmal legend?
      if let tick = legend.tick {
        // YES, calculate the x coordinate of the legend
        let xPosition = CGFloat(tick) * segmentWidth
        
        // format & draw the legend
        let width = legend.label.size(withAttributes: _attributes).width
        legend.label.draw(at: NSMakePoint(xPosition + (width * legend.fudge), _fontY), withAttributes: _attributes)
        
      } else {
        
        // NO, draw a centered legend
        let width = legend.label.size(withAttributes: _attributes).width
        let xPosition = (frame.width / 2.0) - (width / 2.0) + (width * legend.fudge)
        legend.label.draw(at: NSMakePoint(xPosition, _fontY), withAttributes: _attributes)
      }
    }
  }
}

