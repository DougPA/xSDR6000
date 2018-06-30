//
//  RadioViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/14/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000
import SwiftyUserDefaults
import XCGLogger

// --------------------------------------------------------------------------------
// MARK: - RadioPicker Delegate definition
// --------------------------------------------------------------------------------

protocol RadioPickerDelegate: class {
  
  var token: Token? { get set }
  
  /// Open the specified Radio
  ///
  /// - Parameters:
  ///   - radio:          a RadioParameters struct
  ///   - remote:         remote / local
  ///   - handle:         remote handle
  /// - Returns:          success / failure
  ///
  func openRadio(_ radio: RadioParameters?, isWan: Bool, wanHandle: String) -> Bool
  
  /// Close the active Radio
  ///
  func closeRadio()
  
  /// Clear the reply table
  ///
  func clearTable()
}

// --------------------------------------------------------------------------------
// MARK: - Radio View Controller class implementation
// --------------------------------------------------------------------------------

final class RadioViewController             : NSSplitViewController, RadioPickerDelegate {

  @objc dynamic var radio                   = Api.sharedInstance.radio
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _api                          = Api.sharedInstance
  private var _mainWindowController         : MainWindowController?
  private var _radioPickerStoryboard        : NSStoryboard?
  private var _sideStoryboard               : NSStoryboard?
  private var _voltageMeterAvailable        = false
  private var _temperatureMeterAvailable    = false
  private var _versions                     : (api: String, app: String)?
//  private var _activity                     : NSObjectProtocol?

  private let _opusManager                  = OpusManager()
  
  private let kGuiFirmwareSupport           = "2.3.7.x"                     // Radio firmware supported by this App
  private let kVoltageTemperature           = "VoltageTemp"                 // Identifier of toolbar VoltageTemperature toolbarItem

  private let kRadioPickerStoryboardName    = NSStoryboard.Name(rawValue: "RadioPicker")
  private let kSideStoryboardName           = NSStoryboard.Name(rawValue: "Side")
  private let kRadioPickerIdentifier        = NSStoryboard.SceneIdentifier(rawValue: "RadioPicker")
  private let kPcwIdentifier                = "PCW"
  private let kPhoneIdentifier              = "Phone"
  private let kRxIdentifier                 = "Rx"
  private let kEqualizerIdentifier          = "Equalizer"

  private let kConnectFailed                = "Initial Connection failed"   // Error messages
  private let kUdpBindFailed                = "Initial UDP bind failed"
  private let kVersionKey                   = "CFBundleShortVersionString"  // CF constants
  private let kBuildKey                     = "CFBundleVersion"

  private let kLocalTab                     = 0
  private let kRemoteTab                    = 1
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // FIXME: Is this necessary???
//    _activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.latencyCritical, reason: "Good Reason")
    
    // give the Log object (in the API) access to our logger
    Log.sharedInstance.delegate = (NSApp.delegate as! LogHandler)
    
    // setup & register Defaults
    defaults(from: "Defaults.plist")
    
    // set the window title
    title()

    // get the Storyboard containing the RadioPicker
    _radioPickerStoryboard = NSStoryboard(name: kRadioPickerStoryboardName, bundle: nil)
    _sideStoryboard = NSStoryboard(name: kSideStoryboardName, bundle: nil)

    // add notification subscriptions
    addNotifications()
    
    // show/hide the Side view
    splitViewItems[1].isCollapsed = !Defaults[.sideOpen]
    splitView.needsLayout = true
    
    // is the default Radio available?
    if let defaultRadio = defaultRadioFound() {
      
      // YES, open the default radio
      if !openRadio(defaultRadio) {
        Log.sharedInstance.msg("Error opening default radio, \(defaultRadio.name ?? "")", level: .warning, function: #function, file: #file, line: #line)

        // open the Radio Picker
        openRadioPicker( self)
      }
      
    } else {
      
      // NO, open the Radio Picker
      openRadioPicker( self)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  // ----- TOOLBAR -----
  
  /// Respond to the Headphone Gain slider
  ///
  /// - Parameter sender: the Slider
  ///
  @IBAction func headphoneGain(_ sender: NSSlider) {
    
    _api.radio?.headphoneGain = sender.integerValue
  }
  /// Respond to the Lineout Gain slider
  ///
  /// - Parameter sender: the Slider
  ///
  @IBAction func lineoutGain(_ sender: NSSlider) {
    
    _api.radio?.lineoutGain = sender.integerValue
  }
  /// Respond to the Headphone Mute button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func muteHeadphone(_ sender: NSButton) {
    
    _api.radio?.headphoneMute = ( sender.state == NSControl.StateValue.on ? true : false )
  }
  /// Respond to the Lineout Mute button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func muteLineout(_ sender: NSButton) {
    
    _api.radio?.lineoutMute = ( sender.state == NSControl.StateValue.on ? true : false )
  }
  /// Respond to the Pan button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func panButton(_ sender: AnyObject) {
    
    // dimensions are dummy values; when created, will be resized to fit its view
    Panadapter.create(CGSize(width: 50, height: 50))
  }
  /// Respond to the Remote Rx button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func remoteRxButton(_ sender: NSButton) {
    
    // FIXME:
    
    // ask the Radio (hardware) to start/stop Rx Opus
//    _opusManager.remoteRxAudioRequest(sender.state == NSControl.StateValue.on)
  }
  /// Respond to the Remote Tx button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func remoteTxButton(_ sender: NSButton) {
        
    // FIXME:
    
    // ask the Radio (hardware) to start/stop Tx Opus
    _api.radio?.transmit.micSelection = (sender.state == NSControl.StateValue.on ? "PC" : "MIC")
    
    // FIXME: This is just for testing
  }
  /// Respond to the Side button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func sideButton(_ sender: NSButton) {
    
    // open / collapse the Side view
    splitViewItems[1].isCollapsed = (sender.state != NSControl.StateValue.on)
  }
  /// Respond to the Tnf button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tnfButton(_ sender: NSButton) {
    
    // enable / disable Tnf's
    _api.radio?.tnfEnabled = (sender.state == NSControl.StateValue.on)
  }
  
  // ----- MENU -----
  
  /// Respond to the Radio Selection menu, show the RadioPicker as a sheet
  ///
  /// - Parameter sender: the MenuItem
  ///
  @IBAction func openRadioPicker(_ sender: AnyObject) {
    
    // get an instance of the RadioPicker
    let radioPickerTabViewController = _radioPickerStoryboard!.instantiateController(withIdentifier: kRadioPickerIdentifier) as? NSTabViewController
    
    // make this View Controller the delegate of the RadioPickers
    radioPickerTabViewController!.tabViewItems[kLocalTab].viewController!.representedObject = self
    radioPickerTabViewController!.tabViewItems[kRemoteTab].viewController!.representedObject = self
    
    // select the last-used tab
    radioPickerTabViewController!.selectedTabViewItemIndex = ( Defaults[.showRemoteTabView] == false ? kLocalTab : kRemoteTab )
    
    DispatchQueue.main.async {
      
      // show the RadioPicker sheet
      self.presentViewControllerAsSheet(radioPickerTabViewController!)
    }
  }
  /// Respond to the xSDR6000 Quit menu
  ///
  /// - Parameter sender: the Menu item
  ///
  @IBAction func terminate(_ sender: AnyObject) {
    
    NSApp.terminate(self)
  }
  
  // ----- SIDE BUTTONS -----
  
  /// Respond to one of the Side buttons
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func sideButtons(_ sender: NSButton) {
    
    sideView( sender.identifier!.rawValue, show: (sender.state == NSControl.StateValue.on) )
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
    
  /// Set the Window's title
  ///
  func title() {
    
    // have the versions been captured?
    if _versions == nil {
      // NO, get the versions
      _versions = versionInfo(framework: Api.kBundleIdentifier)

      // log them
      Log.sharedInstance.msg("\(kClientName) v\(_versions!.app), xLib6000 v\(_versions!.api)", level: .info, function: #function, file: #file, line: #line)
    }
    
    // format and set the window title
    let title = (_api.activeRadio == nil ? "" : "- Connected to \(_api.activeRadio!.nickname ?? "") @ \(_api.activeRadio!.ipAddress)")
    DispatchQueue.main.async {
      self.view.window?.title = "\(kClientName) v\(self._versions!.app), xLib6000 v\(self._versions!.api) \(title)"
    }
  }
  /// Check if there is a Default Radio
  ///
  /// - Returns:        a RadioParameters struct or nil
  ///
  private func defaultRadioFound() -> RadioParameters? {
    var defaultRadioParameters: RadioParameters?
    
    // see if there is a valid default Radio
    let defaultRadio = RadioParameters( Defaults[.defaultsDictionary] )
    if defaultRadio.ipAddress != "" && defaultRadio.port != 0 {
      
      // allow time to hear the UDP broadcasts
      usleep(1_500_000)
      
      // has the default Radio been found?
      for (_, foundRadio) in _api.availableRadios.enumerated() where foundRadio == defaultRadio {
        
        // YES, Save it in case something changed
        Defaults[.defaultsDictionary] = foundRadio.dictFromParams()
        
        //        // select it in the TableView
        //        self._radioTableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: true)
        
        Log.sharedInstance.msg("\(foundRadio.nickname ?? "") @ \(foundRadio.ipAddress)", level: .info, function: #function, file: #file, line: #line)
        
        defaultRadioParameters = foundRadio
      }
    }
    return defaultRadioParameters
  }
  /// Display / Hide a side view
  ///
  /// - Parameters:
  ///   - identifier:     a Storyboard identifier
  ///   - show:           show?
  ///
  private func sideView(_ identifier: String, show: Bool) {
    
    // get a reference to the Side view controller
    let sideViewController = childViewControllers[1] as? NSSplitViewController
    
    // show or hide?
    if show {
      
      // SHOW, create a view controller
      let sbIdentifier = NSStoryboard.SceneIdentifier( rawValue: identifier)
      let vc = _sideStoryboard!.instantiateController(withIdentifier: sbIdentifier ) as! NSViewController
      vc.identifier = NSUserInterfaceItemIdentifier(rawValue: identifier)
      
      // give it a reference to its Radio object
      vc.representedObject = _api.radio
      
      // add it to the Side View
      sideViewController!.insertChildViewController(vc, at: 1)
      
      // tell the SplitView to adjust
      sideViewController!.splitView.adjustSubviews()
      
    } else {
      
      // HIDE, remove it from the Side View
      for (i, vc) in sideViewController!.childViewControllers.enumerated() where vc.identifier!.rawValue == identifier {
          sideViewController!.removeChildViewController(at: i)
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods

  private var _opusObservers    = [NSKeyValueObservation]()

  /// Add observers for Opus properties
  ///
  private func addOpusObservers(_ opus: Opus) {
    
    _opusObservers = [
      opus.observe(\.remoteRxOn, options: [.initial, .new], changeHandler: opusObserver),
      opus.observe(\.remoteTxOn, options: [.initial, .new], changeHandler: opusObserver),
      opus.observe(\.rxStreamStopped, options: [.initial, .new], changeHandler: opusObserver),
    ]
  }
  /// Remove observers
  ///
  /// - Parameter observers:            an array of NSKeyValueObservation
  ///
  func removeObservers(_ observers: [NSKeyValueObservation]) {

    for observer in observers {
      observer.invalidate()
    }
  }
  /// Respond to Opus observations
  ///
  /// - Parameters:
  ///   - object:                       the object holding the properties
  ///   - change:                       the change
  ///
  private func opusObserver(_ opus: Opus, _ change: Any) {
    
    // FIXME: need code
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(tcpDidConnect(_:)), of: .tcpDidConnect, object: nil)
    
    NC.makeObserver(self, with: #selector(meterHasBeenAdded(_:)), of: .meterHasBeenAdded, object: nil)
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded, object: nil)

    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved, object: nil)

    NC.makeObserver(self, with: #selector(radioHasBeenRemoved(_:)), of: .radioHasBeenRemoved, object: nil)
    
    NC.makeObserver(self, with: #selector(opusHasBeenAdded(_:)), of: .opusHasBeenAdded, object: nil)
    
    NC.makeObserver(self, with: #selector(opusWillBeRemoved(_:)), of: .opusWillBeRemoved, object: nil)
  }
  /// Process .tcpDidConnect Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func tcpDidConnect(_ note: Notification) {
    
    // a tcp connection has been established
    
    // get Radio model & firmware version
    Defaults[.radioFirmwareVersion] = _api.activeRadio!.firmwareVersion!
    Defaults[.radioModel] = _api.activeRadio!.model
  }
  /// Process .meterHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func meterHasBeenAdded(_ note: Notification) {
    
    if let meter = note.object as? Meter {

      // is it one we need to watch?
      switch meter.name {
      case Api.MeterShortName.voltageAfterFuse.rawValue:
        _voltageMeterAvailable = true

      case Api.MeterShortName.temperaturePa.rawValue:
        _temperatureMeterAvailable = true

      default:
        break
      }
      if _voltageMeterAvailable && _temperatureMeterAvailable {

        // start the Voltage/Temperature monitor
        let mainWindowController = view.window?.windowController as? MainWindowController
        mainWindowController?.voltageTempMonitor?.activate(radio: _api.radio!, meterShortNames: [.voltageAfterFuse, .temperaturePa], units: ["v", "c"])
      }
    }
  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func radioHasBeenAdded(_ note: Notification) {
    
    // the Radio class has been initialized
    if let radio = note.object as? Radio {
      
      Log.sharedInstance.msg("\(radio.nickname)", level: .info, function: #function, file: #file, line: #line)

      // update the title bar
      title()
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // the Radio class is being removed
    if let radio = note.object as? RadioParameters {
      
      Log.sharedInstance.msg("\(radio.nickname ?? "")", level: .info, function: #function, file: #file, line: #line)
      
      // remove all objects on Radio
      _api.radio?.removeAll()
      
      // update the title bar
      title()
    }
  }
  /// Process .radioHasBeenRemoved Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func radioHasBeenRemoved(_ note: Notification) {
    
    // the Radio class has been removed
    
    Log.sharedInstance.msg("", level: .info, function: #function, file: #file, line: #line)
    
    // update the window title
    title()
  }
  /// Process .opusHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func opusHasBeenAdded(_ note: Notification) {
    
    // the Opus class has been initialized
    if let opus = note.object as? Opus {

      DispatchQueue.main.sync { [unowned self] in

        // add Opus property observations
        self.addOpusObservers(opus)
      }
    }
  }
  /// Process .opusWillBeRemoved Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func opusWillBeRemoved(_ note: Notification) {
    
    // an Opus class will be removed
    if let _ = note.object as? Opus {

      DispatchQueue.main.sync { [unowned self] in

        // remove Opus property observations
        self.removeObservers(self._opusObservers)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - RadioPicker delegate methods
  
  var token: Token?

  /// Connect the selected Radio
  ///
  /// - Parameters:
  ///   - radio:                the RadioParameters
  ///   - isWan:                Local / Wan
  ///   - wanHandle:            Wan handle (if any)
  /// - Returns:                success / failure
  ///
  func openRadio(_ radio: RadioParameters?, isWan: Bool = false, wanHandle: String = "") -> Bool {
    
    // fail if no Radio selected
    guard let selectedRadio = radio else { return false }
    
    _api.isWan = isWan
    _api.wanConnectionHandle = wanHandle
    
    // attempt to connect to it
    return _api.connect(selectedRadio, clientName: kClientName, isGui: true)
  }
  /// Stop the active Radio
  ///
  func closeRadio() {
    
    _api.disconnect(reason: .normal)
  }
  /// Clear the reply table
  ///
  func clearTable() {
    // unused
  }
}
