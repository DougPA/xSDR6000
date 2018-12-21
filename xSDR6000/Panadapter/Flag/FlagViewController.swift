//
//  FlagViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/22/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

// --------------------------------------------------------------------------------
//  Created by PanadapterViewController - .sliceHasBeenAdded
//  Removed by PanadapterViewController - .sliceWillBeRemoved
//
//  **** Notifications received ****
//      .sliceMeterHasBeenAdded
//
//  **** Observations ****
//      Slice:
//          frequency
//      Panadapter:
//          center
//          bandwidth
//      Meters:
//          .signalPassband
//
//  **** View Bindings ****
//      Slice:
//          anfEnabled
//          frequency
//          locked
//          nbEnabled
//          nrEnabled
//          qskEnabled
//          rcvAnt
//          rcvAntList
//          txAnt
//          txAntList
//          txEnabled
//
//      FlagViewController:
//          filterWidth
//          letterId
// --------------------------------------------------------------------------------

import Cocoa
import xLib6000

// --------------------------------------------------------------------------------
// MARK: - Flag View Controller class implementation
// --------------------------------------------------------------------------------

final public class FlagViewController       : NSViewController, NSTextFieldDelegate {
  
  static let kSliceLetters : [String]       = ["A", "B", "C", "D", "E", "F", "G", "H"]
  static let kFlagOffset                    : CGFloat = 7.5
  static let kLargeFlagWidth                : CGFloat = 290
  static let kLargeFlagHeight               : CGFloat = 100
  static let kSmallFlagWidth                : CGFloat = 132
  static let kSmallFlagHeight               : CGFloat = 55
  static let kFlagBorder                    : CGFloat = 20
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var flagHeightConstraint                  : NSLayoutConstraint?
  var flagWidthConstraint                   : NSLayoutConstraint?
  var flagXPositionConstraint               : NSLayoutConstraint?
  var controlsHeightConstraint              : NSLayoutConstraint?
  var smallFlagDisplayed                    = false
  

  @objc dynamic weak var slice              : xLib6000.Slice?
  @objc dynamic var letterId                : String { return FlagViewController.kSliceLetters[Int(slice!.id)!] }
  @objc dynamic var tx                      : String { return slice!.txEnabled ? "TX" : "" }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _alphaButton   : NSButton!
  @IBOutlet private var _filterWidth        : NSTextField!
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
  private weak var _controlsVc              : ControlsViewController?
  private weak var _panadapterVc            : PanadapterViewController?

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
  private let kAudHeight                    : CGFloat = 98.0
  private let kDspHeight                    : CGFloat = 100.0
  private let kModeHeight                   : CGFloat = 84.0
  private let kXRitHeight                   : CGFloat = 69.0
  private let kDaxHeight                    : CGFloat = 43.0

  private let kSplitCaption                 = "SPLIT"
  private let kSplitOnAttr                  = [NSAttributedString.Key.foregroundColor : NSColor.systemYellow]
  private let kSplitOffAttr                 = [NSAttributedString.Key.foregroundColor : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)]

  private let kLetterAttr                  = [NSAttributedString.Key.foregroundColor : NSColor.systemYellow]

  private let kTxCaption                    = "TX"
  private let kTxOnAttr                     = [NSAttributedString.Key.foregroundColor : NSColor.systemRed]
  private let kTxOffAttr                    = [NSAttributedString.Key.foregroundColor : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)]
  
  private let kAud                          = NSUserInterfaceItemIdentifier(rawValue: "AUD")
  private let kDsp                          = NSUserInterfaceItemIdentifier(rawValue: "DSP")
  private let kMode                         = NSUserInterfaceItemIdentifier(rawValue: "MODE")
  private let kXRit                         = NSUserInterfaceItemIdentifier(rawValue: "XRIT")
  private let kDax                          = NSUserInterfaceItemIdentifier(rawValue: "DAX")

  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    view.translatesAutoresizingMaskIntoConstraints = false

    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5).cgColor

    // find the S-Meter feed (if any, it may alreaady exist or it may come later as a sliceMeterAdded Notification)
    findSMeter()
    
    // create observations of Slice & Panadapter properties
    createObservations(slice: slice!, panadapter: _panadapter!)

    // start receiving Notifications
    addNotifications()
    
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
  func configure(panadapter: Panadapter?, slice: xLib6000.Slice?, controlsVc: ControlsViewController?, panadapterVc: PanadapterViewController) {
    self._panadapter = panadapter
    self.slice = slice!
    self._controlsVc = controlsVc
    self._panadapterVc = panadapterVc

  }
  /// Invalidate observations (optionally remove)
  ///
  /// - Parameters:
  ///   - observations:                 an array of NSKeyValueObservation
  ///   - remove:                       remove all enabled
  ///
  func invalidateObservations(remove: Bool = true) {
    
    // invalidate each observation
    _observations.forEach { $0.invalidate() }
    
    // if specified, remove the tokens
    if remove { _observations.removeAll() }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  @IBAction func alphaButton(_ sender: Any) {
    
    smallFlagDisplayed.toggle()
    
    flagHeightConstraint!.isActive = false
    flagWidthConstraint!.isActive = false

    if smallFlagDisplayed {
      flagHeightConstraint = view.heightAnchor.constraint(equalToConstant: FlagViewController.kSmallFlagHeight)
      flagWidthConstraint = view.widthAnchor.constraint(equalToConstant: FlagViewController.kSmallFlagWidth)

    } else {

      flagHeightConstraint = view.heightAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagHeight)
      flagWidthConstraint = view.widthAnchor.constraint(equalToConstant: FlagViewController.kLargeFlagWidth)
    }
    flagHeightConstraint!.isActive = true
    flagWidthConstraint!.isActive = true

    // position the flag
    _panadapterVc!.positionFlags()
  }
  
  @IBAction func txButton(_ sender: NSButton) {

    slice?.txEnabled = !sender.boolState
  }
  
  @IBAction func splitButton(_ sender: NSButton) {
    sender.attributedTitle = NSAttributedString(string: kSplitCaption, attributes: sender.boolState ? kSplitOnAttr : kSplitOffAttr)
  }
  /// Respond to the cClose button
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
  @IBAction func buttons(_ sender: NSButton) {
    var height : CGFloat = 0.0
    
    // is the button "on"?
    if sender.boolState {

      // YES, turn off any other buttons
      if sender.identifier != kAud { _audButton.boolState = false}
      if sender.identifier != kDsp { _dspButton.boolState = false}
      if sender.identifier != kMode { _modeButton.boolState = false}
      if sender.identifier != kXRit { _xritButton.boolState = false}
      if sender.identifier != kDax { _daxButton.boolState = false}
    
      // select the desired tab
      _controlsVc?.selectedTabViewItemIndex = sender.tag
      
      // set the height of the Controls View
      switch sender.identifier {
      case kAud:
        height = kAudHeight
      case kDsp:
        height = kDspHeight
      case kMode:
        height = kModeHeight
      case kXRit:
        height = kXRitHeight
      case kDax:
        height = kDaxHeight
      default:
        height = 100.0
      }
      controlsHeightConstraint!.isActive = false
      controlsHeightConstraint!.constant = height
      controlsHeightConstraint!.isActive = true

      // unhide the controls
      _controlsVc!.view.isHidden = false

    } else {
      
      // hide the controls
      _controlsVc!.view.isHidden = true
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Find the S-Meter for this Slice (if any)
  ///
  private func findSMeter() {
    
    if let item = slice!.meters.first(where: { $0.value.name == Api.MeterShortName.signalPassband.rawValue} ) {
      observerSMeter( item.value)
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
  private func createObservations(slice: xLib6000.Slice, panadapter: Panadapter ) {
    
    _observations = [
      slice.observe(\.txEnabled, options: [.initial, .new], changeHandler: txRefresh(_:_:)),
      slice.observe(\.filterHigh, options: [.initial, .new], changeHandler: filterRefresh(_:_:)),
      slice.observe(\.filterLow, options: [.initial, .new], changeHandler: filterRefresh(_:_:)),
      slice.observe(\.frequency, options: [.initial, .new], changeHandler: positionFlags(_:_:)),
      panadapter.observe(\.center, options: [.initial, .new], changeHandler: positionFlags(_:_:)),
      panadapter.observe(\.bandwidth, options: [.initial, .new], changeHandler: positionFlags(_:_:))
    ]
  }
  /// Respond to a change in Slice Tx state
  ///
  /// - Parameters:
  ///   - object:               the object that changed
  ///   - change:               the change
  ///
  private func txRefresh(_ slice: xLib6000.Slice, _ change: Any) {

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
  private func filterRefresh(_ slice: xLib6000.Slice, _ change: Any) {
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
  /// Respond to a change in Panadapter or Slice properties
  ///
  /// - Parameters:
  ///   - object:               the object rhat changed
  ///   - change:               the change
  ///
  private func positionFlags(_ object: Any, _ change: Any) {
    
//    Swift.print("FlagViewController: positionFlags, object = \(object), change = \(change), parent = \(parent)")
    
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
        observerSMeter( meter )
      
      default:
        break
      }
    }
  }
  /// Observe the S-Meter feed
  ///
  ///     Note: meters may not be available at Slice creation.
  ///     If not, the .sliceMeterHasBeenAdded notification will identify the S-Meter
  ///
  func observerSMeter(_ meter: Meter) {
    
    // create the observation
    _meterObservations.append( meter.observe(\.value, options: [.initial, .new], changeHandler: meterUpdate(_:_:)) )
  }
  /// Respond to a change in the S-Meter
  ///
  /// - Parameters:
  ///   - object:                 the Meter
  ///   - change:                 the Change
  ///
  private func meterUpdate(_ object: Any, _ change: Any) {
    
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



