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
  static let kFlagOffset                    : CGFloat = 15.0/2.0
  static let kFlagWidth                     : CGFloat = 240
  static let kFlagHeight                    : CGFloat = 145
  static let kFlagBorder                    : CGFloat = 20
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  @objc dynamic weak var slice              : xLib6000.Slice?
  @objc dynamic var letterId                : String { return FlagViewController.kSliceLetters[Int(slice!.id)!] }
  @objc dynamic var filterWidth             : Float { return Float(slice!.filterHigh - slice!.filterLow)/1_000.0 }

  private weak var _panadapter              : Panadapter?
  private var _center                       : Int {return _panadapter!.center }
  private var _bandwidth                    : Int { return _panadapter!.bandwidth }
  private var _start                        : Int { return _center - (_bandwidth/2) }
  private var _end                          : Int  { return _center + (_bandwidth/2) }
  private var _hzPerUnit                    : CGFloat { return CGFloat(_end - _start) / _panadapter!.xPixels }

  private weak var _controlsVc              : ControlsViewController?
  var onLeft                                = true
  var observations                          = [NSKeyValueObservation]()
  var flagXPositionConstraint               : NSLayoutConstraint?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _frequencyField: NSTextField!
  @IBOutlet private weak var _sMeter        : NSLevelIndicator!
  @IBOutlet private weak var _audButton     : NSButton!
  @IBOutlet private weak var _dspButton     : NSButton!
  @IBOutlet private weak var _modeButton    : NSButton!
  @IBOutlet private weak var _xritButton    : NSButton!
  @IBOutlet private weak var _daxButton     : NSButton!
  
  private var _doubleClick                  : NSClickGestureRecognizer!
  private var _previousFrequency            = 0
  private var _beginEditing                 = false
  
  private let kLeftButton                   = 0x01                          // masks for Gesture Recognizers
  private let kFlagPixelOffset              : CGFloat = 15.0/2.0
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden methods
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    // set the background color of the Flag
    view.layer?.backgroundColor = NSColor.lightGray.cgColor

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
    
    view.identifier = NSUserInterfaceItemIdentifier(rawValue: "Slice Flag")
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
  func configure(panadapter: Panadapter?, slice: xLib6000.Slice?, controlsVc: ControlsViewController) {
    self._panadapter = panadapter
    self.slice = slice!
    self._controlsVc = controlsVc

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
  
  /// One of the "tab" view buttons has been clicked
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func buttons(_ sender: NSButton) {
    
    // is the button "on"?
    if sender.boolState {

      // YES, turn off any other buttons
      if sender != _audButton { _audButton.boolState = false}
      if sender != _dspButton { _dspButton.boolState = false}
      if sender != _modeButton { _modeButton.boolState = false}
      if sender != _xritButton { _xritButton.boolState = false}
      if sender != _daxButton { _daxButton.boolState = false}
    
      // select the desired tab
      _controlsVc?.selectedTabViewItemIndex = sender.tag
      
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
  
  private var _observations    = [NSKeyValueObservation]()
  
  /// Add observers for properties used by the Flag
  ///
  private func createObservations(slice: xLib6000.Slice, panadapter: Panadapter ) {
    
    _observations = [
      slice.observe(\.frequency, options: [.initial, .new], changeHandler: positionFlags(_:_:)),
      panadapter.observe(\.center, options: [.initial, .new], changeHandler: positionFlags(_:_:)),
      panadapter.observe(\.bandwidth, options: [.initial, .new], changeHandler: positionFlags(_:_:))
    ]
  }
  /// Respond to a change in Panadapter or Slice properties
  ///
  /// - Parameters:
  ///   - object:               the object rhat changed
  ///   - change:               the change
  ///
  private func positionFlags(_ object: Any, _ change: Any) {
    
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
  private var _levelObservation    : NSKeyValueObservation?
  
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
    _levelObservation = meter.observe(\.value, options: [.initial, .new]) { (meter, change) in
      
      // process observations of the S-Meter
      DispatchQueue.main.async { [unowned self] in
        self._sMeter.floatValue = meter.value
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



