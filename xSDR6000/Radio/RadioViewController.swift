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

// --------------------------------------------------------------------------------
//  Created by Application load
//  Removed by Application termination
//
//  **** Notifications received ****
//      .radioHasBeenAdded -> set Radio version, title & toolbar
//      .radioWillBeRemoved -> clear Radio version & toolbar
//      .radioHasBeenRemoved -> log, clear title
//      .meterHasBeenAdded -> capture meters for ParameterMonitors
//      .opusRxHasBeenAdded -> create Opus components & set stream delegate
//      .tcpDidDisconnect -> alert if caused by error or other user
//
//  **** Menu Actions ****
//      Quit
//      Open RadioPicker sheet
//
//  **** Action Methods ****
//      Quit
//      Mac Audio
//      LineoutAudio gain
//      LineOutAudio mute
//      HeadphoneAudio gain
//      HeadphoneAudio mute
//      Panadapter create
//      SidePanel open/close
//      CWX open/close
//      Markers enable
//      Tnfs enable
//
//  **** Observations ****
//      None
//
//  **** View Bindings ****
//      None
//
// --------------------------------------------------------------------------------

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
}

// --------------------------------------------------------------------------------
// MARK: - Radio View Controller class implementation
// --------------------------------------------------------------------------------

final class RadioViewController             : NSSplitViewController, RadioPickerDelegate {

  @objc dynamic var radio                   = Api.sharedInstance.radio
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "RadioVC")
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

  private let kRadioPickerStoryboardName    = "RadioPicker"
  private let kSideStoryboardName           = "Side"
  private let kRadioPickerIdentifier        = "RadioPicker"
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
    
    identifier = NSUserInterfaceItemIdentifier(rawValue: "RadioViewController")
    view.identifier = NSUserInterfaceItemIdentifier(rawValue: "Radio split view")
        
    // FIXME: Is this necessary???
//    _activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.latencyCritical, reason: "Good Reason")
    
    // setup & register Defaults
    defaults(from: "Defaults.plist")
    
    // set the window title
    updateWindowTitle()

    // get the Storyboard containing the RadioPicker
    _radioPickerStoryboard = NSStoryboard(name: kRadioPickerStoryboardName, bundle: nil)
    _sideStoryboard = NSStoryboard(name: kSideStoryboardName, bundle: nil)

    splitViewItems[1].isCollapsed = true
    
    // add notification subscriptions
    addNotifications()
    
   // is the default Radio available?
    if let defaultRadio = defaultRadioFound() {
      
      // YES, open the default radio
      if !openRadio(defaultRadio) {
        os_log("Error opening default radio, %{public}@", log: _log, type: .default, defaultRadio.nickname)
        
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
  
  @IBAction func quitRadio(_ sender: Any) {
    
    // perform an orderly shutdown of all the components
    _api.shutdown(reason: .normal)
    
    DispatchQueue.main.async {
      os_log("Application closed by user", log: self._log, type: .info)

      // close the app
      NSApp.terminate(sender)
    }
  }

  // ----- TOOLBAR -----
  
  /// Respond to the Mac Audio button
  ///
  /// - Parameter sender:         the Slider
  ///
  @IBAction func opusRxAudio(_ sender: NSButton) {
    
    // enable / disable Remote Audio
    _opus?.rxEnabled = sender.boolState

    let opusRxStatus = sender.boolState ? "Started" : "Stopped"
    
    os_log("Opus Rx - %{public}@", log: _log, type: .default, opusRxStatus)
  }
  /// Respond to the Headphone Gain slider
  ///
  /// - Parameter sender:         the Slider
  ///
  @IBAction func headphoneGain(_ sender: NSSlider) {
    
    _api.radio?.headphoneGain = sender.integerValue
  }
  /// Respond to the Lineout Gain slider
  ///
  /// - Parameter sender:         the Slider
  ///
  @IBAction func lineoutGain(_ sender: NSSlider) {
    
    _api.radio?.lineoutGain = sender.integerValue
  }
  /// Respond to the Headphone Mute button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func muteHeadphone(_ sender: NSButton) {
    
    _api.radio?.headphoneMute = sender.boolState
  }
  /// Respond to the Lineout Mute button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func muteLineout(_ sender: NSButton) {
    
    _api.radio?.lineoutMute = sender.boolState
  }
  /// Respond to the Pan button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func panButton(_ sender: AnyObject) {
    
    // dimensions are dummy values; when created, will be resized to fit its view
    Panadapter.create(CGSize(width: 50, height: 50))
  }
  /// Respond to the Side button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func sideButton(_ sender: NSButton) {
    
    // open / collapse the Side view
    splitViewItems[1].isCollapsed = !sender.boolState
    Defaults[.sideViewOpen] = sender.boolState    
  }
  /// Respond to the Cwx button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func cwxButton(_ sender: NSButton) {
    
    // open / collapse the Cwx view
    
    // FIXME: Implement the Cwx view
    
    Defaults[.cwxViewOpen] = sender.boolState
  }
  /// Respond to the Markers button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func markersButton(_ sender: NSButton) {
    
    // enable / disable Markers
    Defaults[.markersEnabled] = sender.boolState
  }
  /// Respond to the Tnf button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func tnfButton(_ sender: NSButton) {
    
    // enable / disable Tnf's
    _api.radio?.tnfsEnabled = sender.boolState
    Defaults[.tnfsEnabled] = sender.boolState
  }
  /// Respond to the Full Duplex button
  ///
  /// - Parameter sender:         the Button
  ///
  @IBAction func fullDuplexButton(_ sender: NSButton) {
    
    // enable / disable Full Duplex
    _api.radio?.fullDuplexEnabled = sender.boolState
    Defaults[.fullDuplexEnabled] = sender.boolState
  }

  // ----- MENU -----
  
  /// Respond to the Radio Selection menu, show the RadioPicker as a sheet
  ///
  /// - Parameter sender:         the MenuItem
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
      self.presentAsSheet(radioPickerTabViewController!)
    }
  }
  /// Respond to the xSDR6000 Quit menu
  ///
  /// - Parameter sender:         the Menu item
  ///
  @IBAction func terminate(_ sender: AnyObject) {
    
    quitRadio(self)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
    
  /// Set the Window's title. toolbar & side view
  ///
  func updateWindowTitle() {
    
    // have the versions been captured?
    if _versions == nil {
      // NO, get the versions
      _versions = versionInfo(framework: Api.kBundleIdentifier)

      Defaults[.versionApi] = _versions!.api
      Defaults[.versionGui] = _versions!.app
      
      // log them
      os_log("%{public}@, v%{public}@, xLib6000 v%{public}@", log: _log, type: .info, kClientName, _versions!.app, _versions!.api)
    }
    
    // format and set the window title
    let title = (_api.activeRadio == nil ? "" : "- \(_api.activeRadio!.nickname) @ \(_api.activeRadio!.publicIp) (\(_api.isWan ? "SmartLink" : "Local"))")
    DispatchQueue.main.async { [unowned self] in
      
      // Title
      self.view.window?.title = "\(kClientName) v\(self._versions!.app), xLib6000 v\(self._versions!.api) \(title)"
    }
  }
  /// Set the toolbar controls
  ///
  func updateToolbar() {
    
    DispatchQueue.main.async { [unowned self] in
      let mainWindowController = self.view.window?.windowController as? MainWindowController
      mainWindowController!.lineoutGain.integerValue = self._api.radio!.lineoutGain
      mainWindowController!.lineoutMute.state = self._api.radio!.lineoutMute.state
      mainWindowController!.headphoneGain.integerValue = self._api.radio!.headphoneGain
      mainWindowController!.headphoneMute.state = self._api.radio!.headphoneMute.state
      mainWindowController!.sideViewOpen.state = Defaults[.sideViewOpen].state
      mainWindowController!.tnfsEnabled.state = Defaults[.tnfsEnabled].state
      mainWindowController!.fullDuplexEnabled.state = Defaults[.fullDuplexEnabled].state
      mainWindowController!.markersEnabled.state = Defaults[.markersEnabled].state

      self.splitViewItems[1].isCollapsed = !Defaults[.sideViewOpen]
      
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
    if defaultRadio.publicIp != "" && defaultRadio.port != 0 {
      
      // allow time to hear the UDP broadcasts
      usleep(1_500_000)
      
      // has the default Radio been found?
      if let radio = _api.availableRadios.first(where: { $0 == defaultRadio} ) {
        
        // YES, Save it in case something changed
        Defaults[.defaultRadio] = radio.dict

        os_log("Default radio found, %{public}@ @ %{public}@", log: _log, type: .info, radio.nickname, radio.publicIp)

        defaultRadioParameters = radio
      }
    }
    return defaultRadioParameters
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(meterHasBeenAdded(_:)), of: .meterHasBeenAdded)
    
    NC.makeObserver(self, with: #selector(radioHasBeenAdded(_:)), of: .radioHasBeenAdded)

    NC.makeObserver(self, with: #selector(radioWillBeRemoved(_:)), of: .radioWillBeRemoved)

    NC.makeObserver(self, with: #selector(radioHasBeenRemoved(_:)), of: .radioHasBeenRemoved)
    
    NC.makeObserver(self, with: #selector(opusRxHasBeenAdded(_:)), of: .opusRxHasBeenAdded)

    NC.makeObserver(self, with: #selector(tcpDidDisconnect(_:)), of: .tcpDidDisconnect)
  }
  /// Process .meterHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func meterHasBeenAdded(_ note: Notification) {
    
    let meter = note.object as! Meter
    
    // is it one we need to watch?
    switch meter.name {
    case Api.MeterShortName.voltageAfterFuse.rawValue:
      _voltageMeterAvailable = true
      
    case Api.MeterShortName.temperaturePa.rawValue:
      _temperatureMeterAvailable = true
      
    default:
      break
    }
    guard _voltageMeterAvailable == true, _temperatureMeterAvailable == true else { return }
    
    DispatchQueue.main.async { [unowned self] in
      // start the Voltage/Temperature monitor
      let mainWindowController = self.view.window?.windowController as? MainWindowController
      mainWindowController?.voltageTempMonitor?.activate(radio: self._api.radio!, meterShortNames: [.voltageAfterFuse, .temperaturePa], units: ["v", "c"])
    }
    
  }
  /// Process .radioHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func radioHasBeenAdded(_ note: Notification) {
    
    // the Radio class has been initialized
    let radio = note.object as! Radio
    
    os_log("Radio initialized: %{public}@", log: _log, type: .info, radio.nickname)
    
    Defaults[.versionRadio] = radio.version
    Defaults[.radioModel] = _api.activeRadio!.model
    
    // update the title bar
    updateWindowTitle()
    
    // update the toolbar items
    updateToolbar()
    
    // show/hide the Side view
    DispatchQueue.main.async { [unowned self] in
      self.splitViewItems[1].isCollapsed = !Defaults[.sideViewOpen]
    }
  }
  /// Process .radioWillBeRemoved Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func radioWillBeRemoved(_ note: Notification) {
    
    // the Radio class is being removed
    let radio = note.object as! Radio
    
    os_log("Radio will be removed: %{public}@", log: _log, type: .info, radio.nickname)
    
    Defaults[.versionRadio] = ""
    
    // remove all objects on Radio
    radio.removeAll()
    
    if Defaults[.sideViewOpen] {
      DispatchQueue.main.async { [unowned self] in
        self.splitViewItems[1].isCollapsed = true
      }
    }
    
    // update the title bar
    updateWindowTitle()
  }
  /// Process .radioHasBeenRemoved Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func radioHasBeenRemoved(_ note: Notification) {
    
    // the Radio class has been removed
    
    os_log("Radio has been removed", log: _log, type: .info)
    
    // update the window title
    updateWindowTitle()
  }
  /// Process .opusHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func opusRxHasBeenAdded(_ note: Notification) {

    // the Opus class has been initialized
    let opus = note.object as! Opus
    _opus = opus
    
    os_log("Opus Rx added: ID = %{public}@", log: _log, type: .info, opus.id.hex)
    
    _opusDecode = OpusDecode()
    _opusEncode = OpusEncode(opus)
    opus.delegate = _opusDecode
  }
  /// Process .tcpDidDisconnect Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func tcpDidDisconnect(_ note: Notification) {
  
    // get the reason
    let reason = note.object as! xLib6000.Api.DisconnectReason
    
    // TCP connection disconnected
    var explanation: String = ""
    switch reason {
      
    case .normal:
//      closeRadio()
      return
      
    case .error(let errorMessage):
      explanation = errorMessage
    }
    // alert if other than normal
    DispatchQueue.main.sync {
      let alert = NSAlert()
      alert.alertStyle = .informational
      alert.messageText = "xSDR6000 has been disconnected."
      alert.informativeText = explanation
      alert.addButton(withTitle: "Ok")
      alert.runModal()
      
      closeRadio()
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
    
    // perform an orderly shutdown of all the components
    _api.shutdown(reason: .normal)
  }
}
