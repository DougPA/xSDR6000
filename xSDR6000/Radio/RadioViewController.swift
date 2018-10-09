//
//  RadioViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 10/14/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Cocoa
import os.log
import xLib6000
import SwiftyUserDefaults
//import XCGLogger

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
  
  private let _log                          = OSLog(subsystem: "net.k3tzr.xSDR6000", category: "RadioVC")
  private var _api                          = Api.sharedInstance
  private var _mainWindowController         : MainWindowController?
  private var _radioPickerStoryboard        : NSStoryboard?
  private var _sideStoryboard               : NSStoryboard?
  private var _voltageMeterAvailable        = false
  private var _temperatureMeterAvailable    = false
  private var _versions                     : (api: String, app: String)?
//  private var _activity                     : NSObjectProtocol?

  private var _opus                         : Opus?
  private var _opusDecode                   : OpusDecode?
  private var _opusEncode                   : OpusEncode?

  
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
//    Log.sharedInstance.delegate = (NSApp.delegate as! LogHandler)
    
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
    splitViewItems[1].isCollapsed = !Defaults[.sideViewOpen]
    splitView.needsLayout = true
    
    // is the default Radio available?
    if let defaultRadio = defaultRadioFound() {
      
      // YES, open the default radio
      if !openRadio(defaultRadio) {
//        Log.sharedInstance.msg("Error opening default radio, \(defaultRadio.name ?? "")", level: .warning, function: #function, file: #file, line: #line)

        os_log("Error opening default radio, %{public}@", log: _log, type: .default, defaultRadio.name ?? "")
        
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
  
  /// Respond to the Opus RX Enable
  ///
  /// - Parameter sender: the Slider
  ///
  @IBAction func opusRxAudio(_ sender: NSButton) {
    
    // enable / disable Remote Audio
    _opus?.rxEnabled = sender.boolState
//    Log.sharedInstance.msg("\(sender.state == NSControl.StateValue.on ? "Started" : "Stopped")", level: .info, function: #function, file: #file, line: #line)

    let opusRxStatus = sender.boolState ? "Started" : "Stopped"
    
    os_log("Opus Rx - %{public}@", log: _log, type: .default, opusRxStatus)
  }
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
    
    _api.radio?.headphoneMute = sender.boolState
  }
  /// Respond to the Lineout Mute button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func muteLineout(_ sender: NSButton) {
    
    _api.radio?.lineoutMute = sender.boolState
  }
  /// Respond to the Pan button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func panButton(_ sender: AnyObject) {
    
    // dimensions are dummy values; when created, will be resized to fit its view
    Panadapter.create(CGSize(width: 50, height: 50))
  }
//  /// Respond to the Remote Tx button
//  ///
//  /// - Parameter sender: the Button
//  ///
//  @IBAction func remoteTxButton(_ sender: NSButton) {
//
//    // FIXME:
//
//    // ask the Radio (hardware) to start/stop Tx Opus
//    _api.radio?.transmit.micSelection = (sender.boolState ? "PC" : "MIC")
//
//    // FIXME: This is just for testing
//  }
  /// Respond to the Side button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func sideButton(_ sender: NSButton) {
    
    // open / collapse the Side view
    splitViewItems[1].isCollapsed = !sender.boolState
    Defaults[.sideViewOpen] = sender.boolState
  }
  /// Respond to the Cwx button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func cwxButton(_ sender: NSButton) {
    
    // open / collapse the Cwx view
    
    // FIXME: Implement the Cwx view
    
    Defaults[.cwxViewOpen] = sender.boolState
  }
  /// Respond to the Markers button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func markersButton(_ sender: NSButton) {
    
    // enable / disable Markers
    Defaults[.markersEnabled] = sender.boolState
  }
  /// Respond to the Tnf button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tnfButton(_ sender: NSButton) {
    
    // enable / disable Tnf's
    _api.radio?.tnfsEnabled = sender.boolState
    Defaults[.tnfsEnabled] = sender.boolState
  }
  /// Respond to the Full Duplex button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func fullDuplexButton(_ sender: NSButton) {
    
    // enable / disable Full Duplex
    _api.radio?.fullDuplexEnabled = sender.boolState
    Defaults[.fullDuplexEnabled] = sender.boolState
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
    radioPickerTabViewController!.selectedTabViewItemIndex = ( Defaults[.remoteViewOpen] == false ? kLocalTab : kRemoteTab )
    
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
    
    sideView( sender.identifier!.rawValue, show: sender.boolState )
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

      Defaults[.versionApi] = _versions!.api
      Defaults[.versionGui] = _versions!.app
      
      // log them
//      Log.sharedInstance.msg("\(kClientName) v\(_versions!.app), xLib6000 v\(_versions!.api)", level: .info, function: #function, file: #file, line: #line)

      os_log("%{public}@, v%{public}@, xLib6000 v%{public}@", log: _log, type: .info, kClientName, _versions!.app, _versions!.api)
    }
    
    // format and set the window title
    let title = (_api.activeRadio == nil ? "" : "- Connected to \(_api.activeRadio!.nickname ?? "") @ \(_api.activeRadio!.ipAddress)")
    DispatchQueue.main.async {
      self.view.window?.title = "\(kClientName) v\(self._versions!.app), xLib6000 v\(self._versions!.api) \(title)"
    }
  }
  /// Set the toolbar controls
  ///
  func toolbar() {
    
    DispatchQueue.main.async {
      let mainWindowController = self.view.window?.windowController as? MainWindowController
      mainWindowController!.lineoutGain.integerValue = self._api.radio!.lineoutGain
      mainWindowController!.lineoutMute.state = self._api.radio!.lineoutMute.state
      mainWindowController!.headphoneGain.integerValue = self._api.radio!.headphoneGain
      mainWindowController!.headphoneMute.state = self._api.radio!.headphoneMute.state
      mainWindowController!.sideViewOpen.state = Defaults[.sideViewOpen].state
      mainWindowController!.tnfsEnabled.state = Defaults[.tnfsEnabled].state
      mainWindowController!.fullDuplexEnabled.state = Defaults[.fullDuplexEnabled].state
      mainWindowController!.markersEnabled.state = Defaults[.markersEnabled].state

      // FIXME: add other toolbar controls
    }
  }
  /// Check if there is a Default Radio
  ///
  /// - Returns:        a RadioParameters struct or nil
  ///
  private func defaultRadioFound() -> RadioParameters? {
    var defaultRadioParameters: RadioParameters?
    
    // see if there is a valid default Radio
    let defaultRadio = RadioParameters( Defaults[.defaultRadio] )
    if defaultRadio.ipAddress != "" && defaultRadio.port != 0 {
      
      // allow time to hear the UDP broadcasts
      usleep(1_500_000)
      
      // has the default Radio been found?
      for (_, foundRadio) in _api.availableRadios.enumerated() where foundRadio == defaultRadio {
        
        // YES, Save it in case something changed
        Defaults[.defaultRadio] = foundRadio.dictFromParams()
        
        //        // select it in the TableView
        //        self._radioTableView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: true)
        
//        Log.sharedInstance.msg("\(foundRadio.nickname ?? "") @ \(foundRadio.ipAddress)", level: .info, function: #function, file: #file, line: #line)

        os_log("Default radio found, %{public}@ @ %{public}@", log: _log, type: .info, foundRadio.nickname ?? "", foundRadio.ipAddress)
        
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

  /// Remove observers
  ///
  /// - Parameter observers:            an array of NSKeyValueObservation
  ///
  func removeObservers(_ observers: [NSKeyValueObservation]) {

    for observer in observers {
      observer.invalidate()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
//    NC.makeObserver(self, with: #selector(tcpDidConnect(_:)), of: .tcpDidConnect, object: nil)
    
    NC.makeObserver(self, with: #selector(meterHasBeenAdded(_:)), of: .meterHasBeenAdded, object: nil)
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded, object: nil)

    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved, object: nil)

    NC.makeObserver(self, with: #selector(radioHasBeenRemoved(_:)), of: .radioHasBeenRemoved, object: nil)
    
    NC.makeObserver(self, with: #selector(opusRxHasBeenAdded(_:)), of: .opusRxHasBeenAdded, object: nil)
  }
  /// Process .tcpDidConnect Notification
  ///
  /// - Parameter note: a Notification instance
  ///
//  @objc private func tcpDidConnect(_ note: Notification) {
//
//    // a tcp connection has been established
//
//    // get Radio model & firmware version
//    Defaults[.radioVersion] = _api.activeRadio!.firmwareVersion!
//    Defaults[.radioModel] = _api.activeRadio!.model
//  }
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

        DispatchQueue.main.async { [unowned self] in
          // start the Voltage/Temperature monitor
          let mainWindowController = self.view.window?.windowController as? MainWindowController
          mainWindowController?.voltageTempMonitor?.activate(radio: self._api.radio!, meterShortNames: [.voltageAfterFuse, .temperaturePa], units: ["v", "c"])
        }
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
      
//      Log.sharedInstance.msg("\(radio.nickname)", level: .info, function: #function, file: #file, line: #line)
      
      os_log("Radio initialized - %{public}@", log: _log, type: .info, radio.nickname)

      Defaults[.versionRadio] = radio.radioVersion
      Defaults[.radioModel] = _api.activeRadio!.model

      // update the title bar
      title()
      
      // update the toolbar controls
      toolbar()
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // the Radio class is being removed
    if let radio = note.object as? RadioParameters {
      
//      Log.sharedInstance.msg("\(radio.nickname ?? "")", level: .info, function: #function, file: #file, line: #line)
      
      os_log("Radio will be removed - %{public}@", log: _log, type: .info, radio.nickname ?? "")
      
      Defaults[.versionRadio] = ""
      
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
    
//    Log.sharedInstance.msg("", level: .info, function: #function, file: #file, line: #line)
    
    os_log("Radio has been removed - %{public}@", log: _log, type: .info, radio?.nickname ?? "")
    
    // update the window title
    title()
  }
  /// Process .opusHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func opusRxHasBeenAdded(_ note: Notification) {

    // the Opus class has been initialized
    if let opus = note.object as? Opus {
      _opus = opus
      
//      Log.sharedInstance.msg("ID = \(opus.id.hex)", level: .info, function: #function, file: #file, line: #line)

      os_log("Opus Rx added, ID = %{public}@", log: _log, type: .info, opus.id.hex)
      

      _opusDecode = OpusDecode()
      _opusEncode = OpusEncode(opus)
      opus.delegate = _opusDecode
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
