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

//  @objc dynamic var radio                   = Api.sharedInstance.radio
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "RadioVC")
  private var _api                          = Api.sharedInstance
  private var _mainWindowController         : MainWindowController?
  private var _preferencesStoryboard        : NSStoryboard?
  private var _profilesStoryboard           : NSStoryboard?
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

  private let kPreferencesStoryboardName    = "Preferences"
  private let kProfilesStoryboardName       = "Profiles"
  private let kRadioPickerStoryboardName    = "RadioPicker"
  private let kSideStoryboardName           = "Side"
  private let kPreferencesIdentifier        = "Preferences"
  private let kProfilesIdentifier           = "Profiles"
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
    
    // FIXME: Is this necessary???
//    _activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.latencyCritical, reason: "Good Reason")
    
    // setup & register Defaults
    defaults(from: "Defaults.plist")
    
    // schedule the start of other apps (if any)
    scheduleSupportingApps()
    
    // get the versions
    _versions = versionInfo(framework: Api.kBundleIdentifier)
    Defaults[.versionApi] = _versions!.api
    Defaults[.versionGui] = _versions!.app

    // get the Storyboards
    _preferencesStoryboard = NSStoryboard(name: kPreferencesStoryboardName, bundle: nil)
    _profilesStoryboard = NSStoryboard(name: kProfilesStoryboardName, bundle: nil)
    _radioPickerStoryboard = NSStoryboard(name: kRadioPickerStoryboardName, bundle: nil)
    _sideStoryboard = NSStoryboard(name: kSideStoryboardName, bundle: nil)

    splitViewItems[1].isCollapsed = true
    
    // add notification subscriptions
    addNotifications()
    
    // limit color pickers to the ColorWheel
    NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)

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

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    
    switch item.action {
    case #selector(openProfiles(_:)):
      return _api.activeRadio != nil
    
    case #selector(openPreferences(_:)):
      return _api.activeRadio != nil
    
    case #selector(sideButton(_:)):
      return _api.activeRadio != nil

    default:
      return true
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
  /// Respond to the Preferences menu
  ///
  /// - Parameter sender:         the MenuItem
  ///
  @IBAction func openPreferences(_ sender: NSMenuItem) {
    
    // get an instance of the Profiles
    let preferencesWindowController = _preferencesStoryboard!.instantiateController(withIdentifier: kPreferencesIdentifier) as? NSWindowController
    
    DispatchQueue.main.async {
      
      // show the Preferences window
      preferencesWindowController?.showWindow(self)
    }
  }
  /// Respond to the Profiles menu
  ///
  /// - Parameter sender:         the MenuItem
  ///
  @IBAction func openProfiles(_ sender: NSMenuItem) {
  
    // get an instance of the Profiles
    let profilesWindowController = _profilesStoryboard!.instantiateController(withIdentifier: kProfilesIdentifier) as? NSWindowController
    
    DispatchQueue.main.async {
      
      // show the Profiles window
     profilesWindowController?.showWindow(self)
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
    
  private func scheduleSupportingApps() {
    
    (Defaults[.supportingApps] as? [Dictionary<String, Any>])?.forEach({

      // if the app is enabled
      if ($0[InfoPrefsViewController.kEnabled] as! Bool) {
        
        // get the App name
        let appName = ($0[InfoPrefsViewController.kAppName] as! String)
        
        // get the startup delay (ms)
        let delay = ($0[InfoPrefsViewController.kDelay] as! Bool) ? $0[InfoPrefsViewController.kInterval] as! Int : 0
        
        // get the Cmd Line parameters
        let parameters = $0[InfoPrefsViewController.kParameters] as! String
        
        // schedule the launch
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds( delay )) {
          
          // TODO: Add Parameters
          NSWorkspace.shared.launchApplication(appName)

          os_log("%{public}@ launched with delay of %{public}d", log: self._log, type: .info, appName, delay)
        }
      }
    })
  }
  /// Set the Window's title. toolbar & side view
  ///
  func updateWindowTitle(_ radio: Radio? = nil) {
    var title = ""
    
    // is there e Radio?
    if let radio = radio {
      
      // format and set the window title
      title = "v\(radio.version)     \(radio.nickname) (\(_api.isWan ? "SmartLink" : "Local"))"
    }
    DispatchQueue.main.async { [unowned self] in
      // Title
      self.view.window?.title = title
    }
  }
  /// Set the toolbar controls
  ///
  func updateToolbar(_ enabled: Bool) {
    
    DispatchQueue.main.async { [unowned self] in
      
      // enable / disable the toolbar items
      let toolbar = self.view.window!.toolbar
      for item in toolbar!.items {
        item.isEnabled = enabled
      }
      // if active, set the values of the toolbar items
      if enabled {
        
        for item in toolbar!.items {
          
          switch item.itemIdentifier.rawValue {
          case "tnfsEnabled":
            (item.view as! NSButton).boolState = Defaults[.tnfsEnabled]
          case "markersEnabled":
            (item.view as! NSButton).boolState = Defaults[.markersEnabled]
          case "lineoutGain":
            (item.view as! NSSlider).integerValue = self._api.radio!.lineoutGain
          case "headphoneGain":
            (item.view as! NSSlider).integerValue = self._api.radio!.headphoneGain
          case "sideEnabled":
            (item.view as! NSButton).boolState = Defaults[.sideViewOpen]
          case "macAudioEnabled":
            (item.view as! NSButton).boolState = Defaults[.macAudioEnabled]
          case "lineoutMute":
            (item.view as! NSButton).boolState = self._api.radio!.lineoutMute
          case "headphoneMute":
            (item.view as! NSButton).boolState = self._api.radio!.headphoneMute
          case "fdxEnabled":
            (item.view as! NSButton).boolState = Defaults[.fullDuplexEnabled]
          case "cwxEnabled":
            // (item.view as! NSButton).boolState = Defaults[.cwxEnabled]
            break
          case "addPan", "VoltageTemp":
            break
          case "NSToolbarFlexibleSpaceItem", "NSToolbarSpaceItem":
            break
          default:
            Swift.print("\(item.itemIdentifier.rawValue)")
            fatalError()
          }
        }
        self.splitViewItems[1].isCollapsed = !Defaults[.sideViewOpen]
      }
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

    NC.makeObserver(self, with: #selector(updateRequired(_:)), of: .updateRequired)
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
      let toolbar = self.view.window!.toolbar!
      let monitor = toolbar.items.findElement({  $0.itemIdentifier.rawValue == "VoltageTemp"} ) as! ParameterMonitor
      monitor.activate(radio: self._api.radio!, meterShortNames: [.voltageAfterFuse, .temperaturePa], units: ["v", "c"])
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
    updateWindowTitle(radio)
    
    // update the toolbar items
    updateToolbar(true)
    
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
    
    // update the toolbar items
    updateToolbar(false)

    // remove all objects on Radio
    radio.removeAll()
    
    if Defaults[.sideViewOpen] {
      DispatchQueue.main.async { [unowned self] in
        self.splitViewItems[1].isCollapsed = true
      }
    }
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
      alert.beginSheetModal(for: self.view.window!, completionHandler: { (response) in })
      self.closeRadio()
    }
  }
  /// Process .updateRequired Notification
  ///
  /// - Parameter note:     a Notification instance
  ///
  @objc private func updateRequired(_ note: Notification) {
    
    let versions = (note.object as! String).split(separator: ",")
    
    // the API & Radio versions are not compatible
    // alert if other than normal
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.alertStyle = .warning
      alert.messageText = "Version update needed."
      alert.informativeText = "Radio:\tv\(versions[1])\n" +
        "API:\t\tv\(versions[0])\n" + "\n" +
      "Use SmartSDR to perform an update"
      alert.addButton(withTitle: "Ok")
      alert.beginSheetModal(for: self.view.window!, completionHandler: { (response) in })
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
    
//    _api.isWan = isWan
//    _api.wanConnectionHandle = wanHandle
    
    // attempt to connect to it
    return _api.connect(selectedRadio, clientName: kClientName, isGui: true, isWan: isWan, wanHandle: wanHandle)
  }
  /// Stop the active Radio
  ///
  func closeRadio() {
    
    // perform an orderly shutdown of all the components
    _api.shutdown(reason: .normal)
  }
}
