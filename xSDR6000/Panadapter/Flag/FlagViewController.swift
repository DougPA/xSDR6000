//
//  FlagViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/22/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Flag View Controller class implementation
// --------------------------------------------------------------------------------

final public class FlagViewController       : NSViewController, NSTextFieldDelegate {
  
  static let kSliceLetters : [String]       = ["A", "B", "C", "D", "E", "F", "G", "H"]
  static let kFlagOffset                    : CGFloat = 7.5
  static let kFlagMinimumSeparation         : CGFloat = 10
  static let kLargeFlagWidth                : CGFloat = 311
  static let kLargeFlagHeight               : CGFloat = 100
  static let kSmallFlagWidth                : CGFloat = 125 
  static let kSmallFlagHeight               : CGFloat = 52
  static let kFlagBorder                    : CGFloat = 20
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var flagHeightConstraint                  : NSLayoutConstraint?
  var flagWidthConstraint                   : NSLayoutConstraint?
  var flagXPositionConstraint               : NSLayoutConstraint?
  var controlsHeightConstraint              : NSLayoutConstraint?
  var smallFlagDisplayed                    = false
  var isOnLeft                              = true
  var controlsVc                            : ControlsViewController?
  @objc dynamic var slice                   : xLib6000.Slice?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _alphaButton   : NSButton!
  @IBOutlet private weak var _filterWidth   : NSTextField!
  @IBOutlet private weak var _rxAntPopUp    : NSPopUpButton!
  @IBOutlet private weak var _txAntPopUp    : NSPopUpButton!
  
  @IBOutlet private weak var _lockButton    : NSButton!
  @IBOutlet private weak var _nbButton      : NSButton!
  @IBOutlet private weak var _nrButton      : NSButton!
  @IBOutlet private weak var _anfButton     : NSButton!
  @IBOutlet private weak var _qskButton     : NSButton!
  
  
  
  @IBOutlet private var _frequencyField     : NSTextField!
  @IBOutlet private var _sMeter             : LevelIndicator!
  @IBOutlet private var _sLevel             : NSTextField!
 
  @IBOutlet private var _audButton          : NSButton!
  @IBOutlet private var _dspButton          : NSButton!
  @IBOutlet private var _modeButton         : NSButton!
  @IBOutlet private var _xritButton         : NSButton!
  @IBOutlet private var _daxButton          : NSButton!
  @IBOutlet private weak var _txButton      : NSButton!
  
  private weak var _panadapter              : Panadapter?
  private weak var _vc                      : NSViewController?

  private var _center                       : Int {return _panadapter!.center }
  private var _bandwidth                    : Int { return _panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  private var _hzPerUnit                    : CGFloat { return CGFloat(_end - _start) / _panadapter!.xPixels }
  
  private var _observations                 = [NSKeyValueObservation]()
  
  private var _doubleClick                  : NSClickGestureRecognizer!
  private var _previousFrequency            = 0
  private var _beginEditing                 = false

  private let kLeftButton                   = 0x01                          // masks for Gesture Recognizers
  private let kFlagPixelOffset              : CGFloat = 15.0/2.0

  private let kSplitCaption                 = "SPLIT"
  private let kSplitOnAttr                  = [NSAttributedString.Key.foregroundColor : NSColor.systemYellow]
  private let kSplitOffAttr                 = [NSAttributedString.Key.foregroundColor : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)]

  private let kLetterAttr                  = [NSAttributedString.Key.foregroundColor : NSColor.systemYellow]

  private let kTxCaption                    = "TX"
  private let kTxOnAttr                     = [NSAttributedString.Key.foregroundColor : NSColor.systemRed]
  private let kTxOffAttr                    = [NSAttributedString.Key.foregroundColor : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)]
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer?.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor

    // populate the choices
    _rxAntPopUp.addItems(withTitles: slice!.rxAntList)
    _txAntPopUp.addItems(withTitles: slice!.txAntList)
    
    // setup Left Double Click recognizer
    _doubleClick = NSClickGestureRecognizer(target: self, action: #selector(leftDoubleClick(_:)))
    _doubleClick.buttonMask = kLeftButton
    _doubleClick.numberOfClicksRequired = 2
    _frequencyField.addGestureRecognizer(_doubleClick)

    _frequencyField.delegate = self
    
    _sMeter.legends = [            // to skip a legend pass "" as the format
        (1, "1", -0.5),
        (2, "3", -0.5),
        (3, "5", -0.5),
        (4, "7", -0.5),
        (5, "9", -0.5),
        (6, "+20", -0.5),
        (7, "+40", -0.5)
    ]
    _sMeter.font = NSFont(name: "Monaco", size: 10.0)
    
    view.identifier = NSUserInterfaceItemIdentifier(rawValue: "Slice Flag")
    
    _alphaButton.attributedTitle = NSAttributedString(string: FlagViewController.kSliceLetters[Int(slice!.id)!], attributes: kLetterAttr)
  }

  
  public func controlTextDidBeginEditing(_ note: Notification) {

    if let field = note.object as? NSTextField, field == _frequencyField {

      _previousFrequency = slice!.frequency
    }
    _beginEditing = true
  }
  
  public func controlTextDidEndEditing(_ note: Notification) {
    
    if let field = note.object as? NSTextField, field == _frequencyField, _beginEditing {

      repositionPanadapter(center: _center, frequency: _previousFrequency, newFrequency: _frequencyField.integerValue)
      _beginEditing = false
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Internal methods

  /// Configure needed parameters
  ///
  /// - Parameters:
  ///   - panadapter:               a Panadapter reference
  ///   - slice:                    a Slice reference
  ///
  func configure(panadapter: Panadapter?, slice: xLib6000.Slice?, controlsVc: ControlsViewController?, vc: NSViewController) {

    // is this the initial setup for this Flag?
    if _vc == nil {
      
      // YES, save the params
      _panadapter = panadapter
      self.slice = slice!
      self.controlsVc = controlsVc
      _vc = vc
      
      controlsVc?.configure(slice: slice!)

      // find the S-Meter feed (if any, it may alreaady exist or it may come later as a sliceMeterAdded Notification)
      findSMeter()
      
      // create observations of Slice & Panadapter properties
      addObservations(slice: slice!, panadapter: _panadapter!)
      
      // start receiving Notifications
      addNotifications()
      
    } else {
      
      // YES, save the params
      _panadapter = panadapter
      self.slice = slice!
      self.controlsVc = controlsVc
      _vc = vc
      
      controlsVc?.configure(slice: slice!)
      
      // remove all previous observations
      removeObservations()
      
      // find the S-Meter feed (if any, it may alreaady exist or it may come later as a sliceMeterAdded Notification)
      findSMeter()

      // add observations of Slice & Panadapter properties
      addObservations(slice: slice!, panadapter: _panadapter!)
    }
  }
  /// Select one of the Controls views
  ///
  /// - Parameter id:                   an identifier String
  ///
  func selectControls(_ tag: Int) {
    
    switch tag {
    case 0:
      _audButton.performClick(self)
    case 1:
      _dspButton.performClick(self)
    case 2:
      _modeButton.performClick(self)
    case 3:
      _xritButton.performClick(self)
    case 4:
      _daxButton.performClick(self)
    default:
      _audButton.performClick(self)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func alphaButton(_ sender: Any) {
   
    // return if this a Side flag (i.e. not on a Slice)
    guard _vc is PanadapterViewController else { return }
      
    var flagPosition: CGFloat = 0
    let constraints = [flagHeightConstraint!, flagWidthConstraint!, flagXPositionConstraint!]
    
    // toggle Flag size
    smallFlagDisplayed.toggle()
    
    // Disable constraints
    NSLayoutConstraint.deactivate(constraints)
    
    // set Flag size
    let width = (smallFlagDisplayed ? FlagViewController.kSmallFlagWidth : FlagViewController.kLargeFlagWidth)
    let height = (smallFlagDisplayed ? FlagViewController.kSmallFlagHeight : FlagViewController.kLargeFlagHeight)
    constraints[0].constant = height
    constraints[1].constant = width
    
    // set Flag position
    let freqPosition = CGFloat(slice!.frequency - _start) / _hzPerUnit
    flagPosition = (isOnLeft ? freqPosition - width - FlagViewController.kFlagOffset : freqPosition + FlagViewController.kFlagOffset)
    constraints[2].constant = flagPosition
    
    // Enable constraints
    NSLayoutConstraint.activate(constraints)
    
    // evaluate all flag positions
    (_vc as! PanadapterViewController).positionFlags()
  }
  
  @IBAction func txButton(_ sender: NSButton) {

    slice?.txEnabled = !sender.boolState
  }
  
  @IBAction func splitButton(_ sender: NSButton) {
    sender.attributedTitle = NSAttributedString(string: kSplitCaption, attributes: sender.boolState ? kSplitOnAttr : kSplitOffAttr)
    
    notImplemented(sender.title).beginSheetModal(for: NSApp.mainWindow!, completionHandler: { response in } )
  }
  /// Respond to the Close button
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func closeButton(_ sender: NSButton) {
    slice!.remove()
  }
  /// One of the "tab" view buttons has been clicked
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func controlsButtons(_ sender: NSButton) {
    // is the button "on"?
    if sender.boolState {
      
      // YES, turn off any other buttons
      if sender.tag != 0 { _audButton.boolState = false}
      if sender.tag != 1 { _dspButton.boolState = false}
      if sender.tag != 2 { _modeButton.boolState = false}
      if sender.tag != 3 { _xritButton.boolState = false}
      if sender.tag != 4 { _daxButton.boolState = false}

      // select the desired tab
      controlsVc?.selectedTabViewItemIndex = sender.tag
      
    // unhide the controls
    controlsVc!.view.isHidden = false
    
      if _vc is SideViewController { (_vc as! SideViewController).setRxHeight(200) }
      
    } else {
      
      // hide the controls
      controlsVc!.view.isHidden = true

      if _vc is SideViewController { (_vc as! SideViewController).setRxHeight(100) }
    }
  }
  /// One of the popups has been clicked
  ///
  /// - Parameter sender:         the popup
  ///
  @IBAction func popups(_ sender: NSPopUpButton) {
    
    switch sender.identifier!.rawValue {
    case "rxAnt":
      slice?.rxAnt = sender.titleOfSelectedItem!
    case "txAnt":
      slice?.txAnt = sender.titleOfSelectedItem!
    default:
      fatalError()
    }
  }
  /// One of the buttons has been clicked
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    switch sender.identifier!.rawValue {
    case "nb":
      slice?.nbEnabled = sender.boolState
    case "nr":
      slice?.nrEnabled = sender.boolState
    case "anf":
      slice?.anfEnabled = sender.boolState
    case "qsk":
      slice?.qskEnabled = sender.boolState
    default:
      fatalError()
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Find the S-Meter for this Slice (if any)
  ///
  private func findSMeter() {
    
    if let item = slice!.meters.first(where: { $0.value.name == Api.MeterShortName.signalPassband.rawValue} ) {
      addMeterObservation( item.value)
    }
  }
  
  /// Respond to Left Double Click gesture
  ///
  /// - Parameter gr: the GestureRecognizer
  ///
  @objc private func leftDoubleClick(_ gr: NSClickGestureRecognizer) {

    _frequencyField.selectText(self)
  }
  /// Change a Slice frequency while maintaining its position in the Panadapter display
  ///
  /// - Parameters:
  ///   - center:                   the current Panadapter center frequency
  ///   - frequency:                the current Slice frequency
  ///   - newFrequency:             the new SLice frequency
  ///
  private func repositionPanadapter(center: Int, frequency: Int, newFrequency: Int) {
  
    slice!.frequency = newFrequency
    _panadapter!.center = newFrequency - (frequency - center)
  }
 
  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  /// Add observers for properties used by the Flag
  ///
  private func addObservations(slice: xLib6000.Slice, panadapter: Panadapter ) {
    
    _observations.append( slice.observe(\.active, options: [.initial, .new], changeHandler: sliceChange(_:_:)) )
   
    _observations.append( slice.observe(\.txEnabled, options: [.initial, .new], changeHandler: txChange(_:_:)) )
    
    _observations.append( slice.observe(\.filterHigh, options: [.initial, .new], changeHandler: filterChange(_:_:)) )
    _observations.append( slice.observe(\.filterLow, options: [.initial, .new], changeHandler: filterChange(_:_:)) )
    
    _observations.append( slice.observe(\.frequency, options: [.initial, .new], changeHandler: positionChange(_:_:)) )
    _observations.append( panadapter.observe(\.center, options: [.initial, .new], changeHandler: positionChange(_:_:)) )
    _observations.append( panadapter.observe(\.bandwidth, options: [.initial, .new], changeHandler: positionChange(_:_:)) )

    _observations.append( slice.observe(\.nbEnabled, options: [.initial, .new], changeHandler: buttonsChange(_:_:)) )
    _observations.append( slice.observe(\.nrEnabled, options: [.initial, .new], changeHandler: buttonsChange(_:_:)) )
    _observations.append( slice.observe(\.anfEnabled, options: [.initial, .new], changeHandler: buttonsChange(_:_:)) )
    _observations.append( slice.observe(\.qskEnabled, options: [.initial, .new], changeHandler: buttonsChange(_:_:)) )
    _observations.append( slice.observe(\.locked, options: [.initial, .new], changeHandler: buttonsChange(_:_:)) )
    
    _observations.append( slice.observe(\.rxAnt, options: [.initial, .new], changeHandler: antennaChange(_:_:)) )
    _observations.append( slice.observe(\.txAnt, options: [.initial, .new], changeHandler: antennaChange(_:_:)) )
    
  }
  /// Add Observation of the S-Meter feed
  ///
  ///     Note: meters may not be available at Slice creation.
  ///     If not, the .sliceMeterHasBeenAdded notification will identify the S-Meter
  ///
  func addMeterObservation(_ meter: Meter) {
    
    // add the observation
    _observations.append( meter.observe(\.value, options: [.initial, .new], changeHandler: meterChange(_:_:)) )
  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func removeObservations() {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // remove the tokens
    _observations.removeAll()
  }
  /// Respond to a change in Slice Tx state
  ///
  /// - Parameters:
  ///   - object:               the object that changed
  ///   - change:               the change
  ///
  private func txChange(_ slice: xLib6000.Slice, _ change: Any) {

    DispatchQueue.main.async {
      self._txButton.attributedTitle = NSAttributedString(string: self.kTxCaption, attributes: (slice.txEnabled ? self.kTxOnAttr : self.kTxOffAttr))
    }
  }
  /// Respond to a change in Slice Filter width
  ///
  /// - Parameters:
  ///   - object:               the object that changed
  ///   - change:               the change
  ///
  private func filterChange(_ slice: xLib6000.Slice, _ change: Any) {
    var formattedWidth = ""
    
    let width = slice.filterHigh - slice.filterLow
    switch width {
    case 1_000...:
      formattedWidth = String(format: "%2.1fk", Float(width)/1000.0)
    case 0..<1_000:
      formattedWidth = String(format: "%3d", width)
    default:
      formattedWidth = "0"
    }
    DispatchQueue.main.async {
      self._filterWidth.stringValue = formattedWidth
    }

    // update the filter outline
    (parent as? PanadapterViewController)?.redrawFrequencyLegend()
  }
  /// Respond to a change in buttons
  ///
  /// - Parameters:
  ///   - slice:                the slice that changed
  ///   - change:               the change
  ///
  private func buttonsChange(_ slice: xLib6000.Slice, _ change: Any) {
    
    DispatchQueue.main.async {
      self._lockButton.boolState = slice.locked
      self._nbButton.boolState = slice.nbEnabled
      self._nrButton.boolState = slice.nrEnabled
      self._anfButton.boolState = slice.anfEnabled
      self._qskButton.boolState = slice.qskEnabled
    }
  }
  /// Respond to a change in Antennas
  ///
  /// - Parameters:
  ///   - slice:                the slice that changed
  ///   - change:               the change
  ///
  private func antennaChange(_ slice: xLib6000.Slice, _ change: Any) {
    
    DispatchQueue.main.async {
      self._rxAntPopUp.selectItem(withTitle: slice.rxAnt)
      self._txAntPopUp.selectItem(withTitle: slice.txAnt)
    }
  }
  /// Respond to a change in the active Slice
  ///
  /// - Parameters:
  ///   - slice:                the slice that changed
  ///   - change:               the change
  ///
  private func sliceChange(_ slice: xLib6000.Slice, _ change: Any) {
    
    if _vc is SideViewController {
      // this Flag is on a Side view
      
      // TODO: need code
      
    } else {
      
      // This Flag is on a Slice, force a redraw
      (_vc as! PanadapterViewController).redrawFrequencyLegend()
    }
  }
  /// Respond to a change in Panadapter or Slice properties
  ///
  /// - Parameters:
  ///   - object:               the object rhat changed
  ///   - change:               the change
  ///
  private func positionChange(_ object: Any, _ change: Any) {
    
    // move the Flag(s)
    (parent as? PanadapterViewController)?.positionFlags()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(sliceMeterHasBeenAdded(_:)), of: .sliceMeterHasBeenAdded)
  }
  private var _meterObservations    = [NSKeyValueObservation]()
  
  /// Process sliceMeterHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func sliceMeterHasBeenAdded(_ note: Notification) {
    
    // does the Notification contain a Meter object for this Slice?
    if let meter = note.object as? Meter, meter.number == slice?.id {

    // which meter?
      switch meter.name {
      
      // S-Meter
      case Api.MeterShortName.signalPassband.rawValue:
        addMeterObservation( meter )
      
      default:
        break
      }
    }
  }
  /// Respond to a change in the S-Meter
  ///
  /// - Parameters:
  ///   - object:                 the Meter
  ///   - change:                 the Change
  ///
  private func meterChange(_ object: Any, _ change: Any) {
    
    DispatchQueue.main.async { [unowned self] in

      let meter = object as! Meter

      self._sMeter.level = CGFloat(meter.value)
      switch meter.value {
      case ..<(-121):
        self._sLevel.stringValue = " S0"
      case (-121)..<(-115):
        self._sLevel.stringValue = " S1"
      case (-115)..<(-109):
        self._sLevel.stringValue = " S2"
      case (-109)..<(-103):
        self._sLevel.stringValue = " S3"
      case (-103)..<(-97):
        self._sLevel.stringValue = " S4"
      case (-103)..<(-97):
        self._sLevel.stringValue = " S5"
      case (-97)..<(-91):
        self._sLevel.stringValue = " S6"
      case (-91)..<(-85):
        self._sLevel.stringValue = " S7"
      case (-85)..<(-79):
        self._sLevel.stringValue = " S8"
      case (-79)..<(-73):
        self._sLevel.stringValue = " S9"
      case (-73)..<(-63):
        self._sLevel.stringValue = "+10"
      case (-63)..<(-53):
        self._sLevel.stringValue = "+20"
      case (-53)..<(-43):
        self._sLevel.stringValue = "+30"
      case (-43)...:
        self._sLevel.stringValue = "+40"
      default:
        break
      }
    }
  }
}
// --------------------------------------------------------------------------------
// MARK: - Frequency Formatter class implementation
// --------------------------------------------------------------------------------

class FrequencyFormatter: NumberFormatter {
  
  private let _maxFrequency = 54_000_000
  private let _minFrequency = 100_000
  
  override init() {
    super.init()
    groupingSeparator = "."
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, range rangep: UnsafeMutablePointer<NSRange>?) throws {
    
    // remove any non-numeric characters
    let number = string.numbers
    
    if number.lengthOfBytes(using: .utf8) > 0 {
      // convert to an Int
      let intValue = Int(string.numbers)!
      
      // return the value as an NSNumber
      obj?.pointee = NSNumber(value: intValue)
    }
  }
  
  override func string(for obj: Any?) -> String? {
    // guard that it's an Int
    guard let intValue = obj as? Int else { return nil }
    
    // make a String version, get its length
    var stringValue = String(intValue)
    let stringLen = stringValue.lengthOfBytes(using: .utf8)
    
    switch stringLen {
      
    case 9...:
      stringValue = String(stringValue.dropLast(stringLen - 8))
      fallthrough
      
    case 7...8:
      let endIndex = stringValue.endIndex
      stringValue.insert(".", at: stringValue.index(endIndex, offsetBy: -3))
      stringValue.insert(".", at: stringValue.index(endIndex, offsetBy: -6))
      
    case 6:
      stringValue += "0"
      let endIndex = stringValue.endIndex
      stringValue.insert(".", at: stringValue.index(endIndex, offsetBy: -3))
      stringValue.insert(".", at: stringValue.index(endIndex, offsetBy: -6))
      
    case 4...5:
      stringValue += ".000"
      let endIndex = stringValue.endIndex
      stringValue.insert(".", at: stringValue.index(endIndex, offsetBy: -6))
      
    default:
      return nil
    }
    return stringValue
  }
}



