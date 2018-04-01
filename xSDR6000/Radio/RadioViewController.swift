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
  
  /// Close this sheet
  ///
  func closeRadioPicker()
  
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
  
  /// Close the application
  ///
  func terminateApp()
}

// --------------------------------------------------------------------------------
// MARK: - Radio View Controller class implementation
// --------------------------------------------------------------------------------

final class RadioViewController             : NSSplitViewController, RadioPickerDelegate {

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _api                          = Api.sharedInstance
  private var _sideViewController           : NSSplitViewController?
  private var _panafallsViewController      : PanafallsViewController?
  private var _mainWindowController         : MainWindowController?
  private var _notifications                = [NSObjectProtocol]()          // Notification observers
  private var _radioPickerTabViewController : NSTabViewController?          // RadioPicker sheet controller
  private var _voltageTempMonitor           : ParameterMonitor?             // the Voltage/Temp ParameterMonitor
  
  private let _opusManager                  = OpusManager()
  
  private let kGuiFirmwareSupport           = "2.0.19.x"                    // Radio firmware supported by this App
  private let kxLib6000Identifier           = "net.k3tzr.xLib6000"          // Bundle identifier for xLib6000
  private let kVoltageMeter                 = "+13.8b"                      // Short name of voltage meter
  private let kPaTempMeter                  = "patemp"                      // Short name of temperature meter
  private let kVoltageTemperature           = "VoltageTemp"                 // Identifier of toolbar VoltageTemperature toolbarItem

  private let kMainStoryboard               = "Main"                        // Storyboard identifier
  private let kPanafallStoryboard           = "Panafall"
  private let kRadioPickerStoryboard        = "RadioPicker"
  private let kSideStoryboard               = "Side"

  private let kRadioPickerIdentifier        = "RadioPicker"
  private let kPcwIdentifier                = "PCW"
  private let kPhoneIdentifier              = "Phone"
  private let kRxIdentifier                 = "Rx"
  private let kEqualizerIdentifier          = "Equalizer"

  private let kConnectFailed                = "Initial Connection failed"   // Error messages
  private let kUdpBindFailed                = "Initial UDP bind failed"
  private let kVersionKey                   = "CFBundleShortVersionString"  // CF constants
  private let kBuildKey                     = "CFBundleVersion"

  private let kLocalTab                       = 0
  private let kRemoteTab                      = 1

  private enum ToolbarButton                : String {                      // toolbar item identifiers
    case Pan, Tnf, Markers, Remote, Speaker, Headset, VoltTemp, Side
  }
  
  private var activity                        : NSObjectProtocol?
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // FIXME: Is this necessary???
    activity = ProcessInfo().beginActivity(options: ProcessInfo.ActivityOptions.latencyCritical, reason: "Good Reason")
    
    // give the Log object (in the API) access to our logger
    Log.sharedInstance.delegate = (NSApp.delegate as! LogHandler)
    
    // register the User defaults
    setupDefaults()
    
    // add notification subscriptions
    addNotifications()
    
    _panafallsViewController = (childViewControllers[0] as! PanafallsViewController)
    //        _panafallsViewController!.representedObject = self
    
    _sideViewController = childViewControllers[1] as? NSSplitViewController
    
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
    _api.radio?.panafallCreate(CGSize(width: 50, height: 50))
  }
  /// Respond to the Remote Rx button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func remoteRxButton(_ sender: NSButton) {
    
    // ask the Radio (hardware) to start/stop Rx Opus
    _api.radio?.remoteRxAudioRequest(sender.state == NSControl.StateValue.on)
  }
  /// Respond to the Remote Tx button
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func remoteTxButton(_ sender: NSButton) {
    
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
    
    // get the Storyboard containing the RadioPicker
    let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: kRadioPickerStoryboard), bundle: nil)

    // get an instance of the RadioPicker
    _radioPickerTabViewController = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "RadioPicker")) as? NSTabViewController
    
    // make this View Controller the delegate of the RadioPickers
    _radioPickerTabViewController!.tabViewItems[kLocalTab].viewController!.representedObject = self
    _radioPickerTabViewController!.tabViewItems[kRemoteTab].viewController!.representedObject = self
    
    // select the last-used tab
    _radioPickerTabViewController!.selectedTabViewItemIndex = ( Defaults[.showRemoteTabView] == false ? kLocalTab : kRemoteTab )
    
    DispatchQueue.main.async {
      
      // show the RadioPicker sheet
      self.presentViewControllerAsSheet(self._radioPickerTabViewController!)
    }
  }
  /// Respond to the xSDR6000 Quit menu
  ///
  /// - Parameter sender: the Menu item
  ///
  @IBAction func quitXFlex(_ sender: AnyObject) {
    
    NSApp.terminate(self)
  }
  
  // ----- SIDE BUTTONS -----
  
  /// Respond to the Eq button (Side view)
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tabEq(_ sender: NSButton) {
    
    if sender.state == NSControl.StateValue.on {
      
      // get the Storyboard containing the Side views
      let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: kSideStoryboard), bundle: nil)
      
      // create an Equalizer view controller
      let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: kEqualizerIdentifier)) as! EqViewController
      
      // give it a reference to its Radio object
      vc.representedObject = _api.radio
      
      // add it to the Side View
      _sideViewController!.insertChildViewController(vc, at: 1)
      
      // tell the SplitView to adjust
      _sideViewController!.splitView.adjustSubviews()
      
    } else {
      
      // remove it from the Side View
      for (i, vc) in _sideViewController!.childViewControllers.enumerated() where vc is EqViewController {
        _sideViewController!.removeChildViewController(at: i)
      }
    }
  }
  /// Respond to the Pcw button (Side view)
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tabPcw(_ sender: NSButton) {
    
    if sender.state == NSControl.StateValue.on {
      
      // create a new Equalizer UI
      let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: kSideStoryboard), bundle: nil)
      
      // create an Pcw view controller
      let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: kPcwIdentifier)) as! PCWViewController
      
      // give it a reference to its Radio object
      vc.representedObject = _api.radio
      
      // add it to the Side View
      _sideViewController!.insertChildViewController(vc, at: 1)
      
      // tell the SplitView to adjust
      _sideViewController!.splitView.adjustSubviews()
      
    } else {
      
      // remove it from the Side View
      for (i, vc) in _sideViewController!.childViewControllers.enumerated() where vc is PCWViewController {
        _sideViewController!.removeChildViewController(at: i)
      }
    }
  }
  /// Respond to the Phne button (Side view)
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tabPhne(_ sender: NSButton) {
    
    if sender.state == NSControl.StateValue.on {
      
      // create a new Equalizer UI
      let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: kSideStoryboard), bundle: nil)
      
      // create an Phone view controller
      let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: kPhoneIdentifier)) as! PhoneViewController
      
      // give it a reference to its Radio object
      vc.representedObject = _api.radio
      
      // add it to the Side View
      _sideViewController!.insertChildViewController(vc, at: 1)
      
      // tell the SplitView to adjust
      _sideViewController!.splitView.adjustSubviews()
      
    } else {
      
      // remove it from the Side View
      for (i, vc) in _sideViewController!.childViewControllers.enumerated() where vc is PhoneViewController {
        _sideViewController!.removeChildViewController(at: i)
      }
    }
  }
  /// Respond to the Rx button (Side view)
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tabRx(_ sender: NSButton) {
    
    if sender.state == NSControl.StateValue.on {
      
      // create a new Equalizer UI
      let sb = NSStoryboard(name: NSStoryboard.Name(rawValue: kSideStoryboard), bundle: nil)
      
      // create an Rx view controller
      let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: kRxIdentifier)) as! NSViewController
      
      // give it a reference to its Radio object
      vc.representedObject = _api.radio
      
      // add it to the Side View
      _sideViewController!.insertChildViewController(vc, at: 1)
      
      // tell the SplitView to adjust
      _sideViewController!.splitView.adjustSubviews()
      
    } else {
      
      // remove it from the Side View
      for (i, vc) in _sideViewController!.childViewControllers.enumerated() where vc is RxViewController {
        _sideViewController!.removeChildViewController(at: i)
      }
    }
  }
  /// Respond to the Tx button (Side view)
  ///
  /// - Parameter sender: the Button
  ///
  @IBAction func tabTx(_ sender: NSButton) {
    
    if sender.state == NSControl.StateValue.on {
      
      // FIXME: Code needed
      
      // show the tab
      print("txTab - SHOW")
      
    } else {
      
      // FIXME: Code needed
      
      // hide the tab
      print("txTab - HIDE")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Setup & Register User Defaults
  ///
  private func setupDefaults() {
    
    // get the URL of the defaults file
    let defaultsUrl = Bundle.main.url(forResource: "Defaults", withExtension: "plist")!
    
    // load the contents
    let myDefaults = NSDictionary(contentsOf: defaultsUrl)!
    
    // register the defaults
    Defaults.register(defaults: myDefaults as! Dictionary<String, Any>)
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
      usleep(1500)
      
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
  /// An observed Meter has been updated
  ///
  /// - Parameter meter: the Meter
  ///
  @objc private func meterUpdated(_ note: Notification) {
    
    // if the note contains a Meter
    if let meter = note.object as? Meter {
      
      // process the update
      processMeterUpdate(meter)
    }
  }
  /// The value of a meter needs to be processed
  ///
  /// - Parameter meter: a Meter instance
  ///
  private func processMeterUpdate(_ meter: Meter) {
    
    // interact with the UI
    DispatchQueue.main.async {
      
      // if no reference to the toolbar item
      if self._voltageTempMonitor == nil {
        
        // get the toolbar
        if let toolbar = NSApp.mainWindow?.toolbar {
          
          // find the VoltageTemperature toolbar item
          let items = toolbar.items.filter( {$0.itemIdentifier.rawValue == self.kVoltageTemperature} )
          
          // there should be only one
          if items.count == 1 {
            
            // save a reference to it
            self._voltageTempMonitor = items[0] as? ParameterMonitor
          }
        }
      }
      // if found, get the units
      if self._voltageTempMonitor != nil {
        
        // check for unknown Units
        guard let token = Meter.Units(rawValue: meter.units) else {
          
          // unknown Units, log it and ignore it
          Log.sharedInstance.msg("Unknown units - \(meter.units) on Meter \(meter.name)", level: .debug, function: #function, file: #file, line: #line)
          return
        }
        // make a short version of the Units
        var shortUnits = ""
        
        switch token {
          
        case .amps:
          shortUnits = "a"
        case .dbfs:
          shortUnits = "f"
        case .dbm:
          shortUnits = "d"
        case .degc:
          shortUnits = "c"
        case .swr:
          shortUnits = "s"
        case .volts:
          shortUnits = "v"
        }
        
        // set the value & units
        if meter.name == self.kVoltageMeter {
          
          // Top (Voltage), set the high / low limits
          self._voltageTempMonitor?.topLimits.high = meter.high
          self._voltageTempMonitor?.topLimits.low = meter.low
          // set the value & units
          self._voltageTempMonitor?.topUnits = shortUnits
          self._voltageTempMonitor?.topValue = meter.value
          
        } else if meter.name == self.kPaTempMeter {
          
          // Bottom (Temperature), set the high / low limits
          self._voltageTempMonitor?.bottomLimits.high = meter.high
          self._voltageTempMonitor?.bottomLimits.low = meter.low
          // set the value & units
          self._voltageTempMonitor?.bottomUnits = shortUnits
          self._voltageTempMonitor?.bottomValue = meter.value
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Observation methods
  
  private let _radioKeyPaths = [
    #keyPath(Radio.lineoutGain),
    #keyPath(Radio.lineoutMute),
    #keyPath(Radio.headphoneGain),
    #keyPath(Radio.headphoneMute),
    #keyPath(Radio.tnfEnabled),
    #keyPath(Radio.fullDuplexEnabled)
  ]
  
  private let _opusKeyPaths = [
    #keyPath(Opus.remoteRxOn),
    #keyPath(Opus.remoteTxOn),
    #keyPath(Opus.rxStreamStopped)
  ]
  /// Add / Remove property observations
  ///
  /// - Parameters:
  ///   - object:           the object of the observations
  ///   - paths:            an array of KeyPaths
  ///   - add:              add / remove (defaults to add)
  ///
  private func observations<T: NSObject>(_ object: T, paths: [String], remove: Bool = false) {

    // for each KeyPath Add / Remove observations
    for keyPath in paths {

      if remove { object.removeObserver(self, forKeyPath: keyPath, context: nil) }
      else { object.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil) }
    }
  }
  /// Process changes to observed keyPaths (may arrive on any thread)
  ///
  /// - Parameters:
  ///   - keyPath:          the KeyPath that changed
  ///   - object:           the Object of the KeyPath
  ///   - change:           a change dictionary
  ///   - context:          a pointer to a context (if any)
  ///
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
    if let kp = keyPath, let ch = change {
      
      if kp != "springLoaded" {
        
        // interact with the UI
        DispatchQueue.main.async { [unowned self] in
          
          switch kp {
            
          case #keyPath(Radio.lineoutGain):
            self._mainWindowController?.lineoutGain.integerValue = ch[.newKey] as! Int
            
          case #keyPath(Radio.lineoutMute):
            self._mainWindowController?.lineoutMute.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.on : NSControl.StateValue.off
            
          case #keyPath(Radio.headphoneGain):
            self._mainWindowController?.headphoneGain.integerValue = ch[.newKey] as! Int
            
          case #keyPath(Radio.headphoneMute):
            self._mainWindowController?.headphoneMute.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.on : NSControl.StateValue.off
            
          case #keyPath(Radio.tnfEnabled):
            self._mainWindowController?.tnfEnabled.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.on : NSControl.StateValue.off
            
          case #keyPath(Radio.fullDuplexEnabled):
            self._mainWindowController?.fdxEnabled.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.on : NSControl.StateValue.off
            
          case #keyPath(Opus.remoteRxOn):
            
            if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
              
              if start == true && opus.delegate == nil {
                
                // Opus starting, supply a decoder
                self._opusManager.rxAudio(true)
                opus.delegate = self._opusManager
                
              } else if start == false && opus.delegate != nil {
                
                // opus stopping, remove the decoder
                self._opusManager.rxAudio(false)
                opus.delegate = nil
              }
            }
            
          case #keyPath(Opus.remoteTxOn):
            
            if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
              
              // Tx Opus starting / stopping
              self._opusManager.txAudio( start, opus: opus )
            }
            
          case #keyPath(Opus.rxStreamStopped):
            
            // FIXME: Implement this
            break
            
          default:
            // log and ignore any other keyPaths
            Log.sharedInstance.msg("Unknown observation - \(String(describing: keyPath))", level: .error, function: #function, file: #file, line: #line)
          }
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(tcpDidConnect(_:)), of: .tcpDidConnect, object: nil)
    
    //        NC.makeObserver(self, with: #selector(tcpDidDisconnect(_:)), of: .tcpDidDisconnect, object: nil)
    //
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
    
    // get the version info from xLib6000
    let frameworkBundle = Bundle(identifier: kxLib6000Identifier)
    let apiVersion = frameworkBundle?.object(forInfoDictionaryKey: kVersionKey) ?? "0"
    let apiBuild = frameworkBundle?.object(forInfoDictionaryKey: kBuildKey) ?? "0"
    
    Defaults[.apiVersion] = "\(apiVersion).\(apiBuild)"
    
    Log.sharedInstance.msg("Using xLib6000 version " + Defaults[.apiVersion], level: .info, function: #function, file: #file, line: #line)
    
    Defaults[.apiFirmwareSupport] = _api.kApiFirmwareSupport
    
    // get the version info for this app
    let appVersion = Bundle.main.object(forInfoDictionaryKey: kVersionKey) ?? "0"
    let appBuild = Bundle.main.object(forInfoDictionaryKey: kBuildKey) ?? "0"
    
    Defaults[.guiVersion] = "\(appVersion).\(appBuild)"
    Defaults[.guiFirmwareSupport] = kGuiFirmwareSupport
    
    // observe changes to Radio properties
    observations(_api.radio!, paths: _radioKeyPaths)
  }
  /// Process .tcpDidDisconnect Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  //    @objc private func tcpDidDisconnect(_ note: Notification) {
  //
  //        // the TCP connection has disconnected
  //        if (note.object as! Radio.DisconnectReason) != .closed {
  //
  //            // not a normal disconnect
  //            openRadioPicker(self)
  //        }
  //    }
  /// Process .meterHasBeenAdded Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func meterHasBeenAdded(_ note: Notification) {
    
    if let meter = note.object as? Meter {
      
      // is it one we need to watch?
      if meter.name == self.kVoltageMeter || meter.name == self.kPaTempMeter {
        
        // YES, process the initial meter reading
        processMeterUpdate(meter)
        
        // subscribe to its updates
        NC.makeObserver(self, with: #selector(meterUpdated(_:)), of: .meterUpdated, object: meter)
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
      
//      // remember the active Radio
//      self.radio = radio

      Log.sharedInstance.msg("\(radio.nickname)", level: .info, function: #function, file: #file, line: #line)

      DispatchQueue.main.sync { [unowned self] in
        
        // Get a reference to the Window Controller containing the toolbar items
        self._mainWindowController = self.view.window?.windowController as? MainWindowController
        
        // Initialize the toolbar items
        self._mainWindowController?.lineoutGain.integerValue = radio.lineoutGain
        self._mainWindowController?.lineoutMute.state = radio.lineoutMute ? NSControl.StateValue.on : NSControl.StateValue.off
        self._mainWindowController?.headphoneGain.integerValue = radio.headphoneGain
        self._mainWindowController?.headphoneMute.state = radio.headphoneMute ? NSControl.StateValue.on : NSControl.StateValue.off
        self._mainWindowController?.window?.viewsNeedDisplay = true
        
        let title = (_api.activeRadio == nil ? "" : " (\(_api.activeRadio!.nickname ?? "") @ \(_api.activeRadio!.ipAddress))")
        self.view.window?.title = "xSDR6000\(title)"
      }
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
    let title = ""
    self.view.window?.title = "xSDR6000\(title)"
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
        self.observations(opus, paths: self._opusKeyPaths)
      }
    }
  }
  /// Process .opusWillBeRemoved Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func opusWillBeRemoved(_ note: Notification) {
    
    // an Opus class will be removed
    if let opus = note.object as? Opus {
      
      DispatchQueue.main.sync { [unowned self] in
        
        // remove Opus property observations
        self.observations(opus, paths: self._opusKeyPaths, remove: true)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - RadioPicker delegate methods
  
  var token: Token?

  /// Stop the active Radio
  ///
  func closeRadio() {
    
    // remove observations of Radio properties
    observations(_api.radio!, paths: _radioKeyPaths, remove: true)
    
    _api.disconnect(reason: .normal)
  }
  /// Connect the selected Radio
  ///
  /// - Parameters:
  ///   - radio:                the RadioParameters
  ///   - isWan:                Local / Wan
  ///   - wanHandle:            Wan handle (if any)
  /// - Returns:                success / failure
  ///
  func openRadio(_ radio: RadioParameters?, isWan: Bool = false, wanHandle: String = "") -> Bool {
    
    // close the Radio Picker (if open)
    closeRadioPicker()
    
    // fail if no Radio selected
    guard let selectedRadio = radio else { return false }
    
    _api.isWan = isWan
    _api.wanConnectionHandle = wanHandle
    
    // attempt to connect to it
    return _api.connect(selectedRadio, clientName: kClientName, isGui: true)
  }
  /// Close the RadioPicker sheet
  ///
  func closeRadioPicker() {
    
    // close the RadioPicker
    if _radioPickerTabViewController != nil {
      dismissViewController(_radioPickerTabViewController!)
      _radioPickerTabViewController = nil }
  }
  /// Clear the reply table
  ///
  func clearTable() {
    // unused
  }
  /// Close the application
  ///
  func terminateApp() {
    
    NSApp.terminate(self)
  }
  

}
