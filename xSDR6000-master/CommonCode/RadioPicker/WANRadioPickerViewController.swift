//
//  WANRadioPickerViewController.swift
//  CommonCode
//
//  Created by Mario Illgen on 08.02.18.
//  Copyright © 2018 Mario Illgen. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

#if XSDR6000
  import xLib6000
#endif

public struct Token {

  var value         : String
  var expiresAt     : Date

  public func isValidAtDate(_ date: Date) -> Bool {
    return (date < self.expiresAt)
  }
}

// --------------------------------------------------------------------------------
// MARK: - WAN RadioPicker Delegate definition
// --------------------------------------------------------------------------------

protocol WANRadioPickerDelegate             : LANRadioPickerDelegate {
  
  var token: Token? {get set}
}

final class WANRadioPickerViewController    : NSViewController, NSTableViewDelegate, NSTableViewDataSource, Auth0ControllerDelegate, WanServerDelegate {
  
  static let kServiceName                   = ".oauth-token"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private var _radioTableView     : NSTableView!                  // table of Radios
  @IBOutlet private var _selectButton       : NSButton!                     // Connect / Disconnect
  @IBOutlet private weak var _gravatarView  : NSImageView!
  @IBOutlet private weak var _nameLabel     : NSTextField!
  @IBOutlet private weak var _callLabel     : NSTextField!
  @IBOutlet private weak var _loginButton   : NSButton!
  
  private var _api                          = Api.sharedInstance
  private var _auth0ViewController          : Auth0ViewController?
  private var _availableRemoteRadios        = [RadioParameters]()           // Radios discovered
  private weak var _delegate                : RadioPickerDelegate? {
    return representedObject as? RadioPickerDelegate
  }
  private var _selectedRadio                : RadioParameters?              // Radio in selected row
  private var _wanServer                    : WanServer?
  
  // constants
  private let kApplicationJson              = "application/json"
  private let kAuth0Delegation              = "https://frtest.auth0.com/delegation"
  private let kClaimEmail                   = "email"
  private let kClaimPicture                 = "picture"
  private let kConnectTitle                 = "Connect"
  private let kDisconnectTitle              = "Disconnect"
  private let kGrantType                    = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  private let kHttpHeaderField              = "content-type"
  private let kHttpPost                     = "POST"

  private let kKeyClientId                  = "client_id"                   // dictionary keys
  private let kKeyGrantType                 = "grant_type"
  private let kKeyIdToken                   = "id_token"
  private let kKeyRefreshToken              = "refresh_token"
  private let kKeyScope                     = "scope"
  private let kKeyTarget                    = "target"

  private let kLowBWTitle                   = "Low BW Connect"
  private let kLoginTitle                   = "Log In"
  private let kLogoutTitle                  = "Log Out"
  private let kPlatform                     = "macOS"
  private let kScope                        = "openid email given_name family_name picture"
  private let kService                      = kClientName + kServiceName
  private let kUpnpIdentifier               = "upnpSupported"
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    super.viewDidLoad()
    
    var idToken = ""
    var loggedIn = false
    
    // allow the User to double-click the desired Radio
    _radioTableView.doubleAction = #selector(WANRadioPickerViewController.selectButton(_:))
    
    _selectButton.title = kConnectTitle
    _loginButton.title = kLoginTitle
    _nameLabel.stringValue = ""
    _callLabel.stringValue = ""
    
    // TODO: put this on a background queue??
    // check if we have logged in into Auth0 and try to get a token using the refresh token from the Keychain

    // 1. is there a saved token which has not expired?
    if let previousIdToken = _delegate?.token, previousIdToken.isValidAtDate( Date()) {
      // YES, save it
      idToken = previousIdToken.value
      loggedIn = true
    }
    // 2 if not check if we have a refresh token for the last email (user defaults) in the keychain
    // if not --> Auth0 login window
    // if yes --> try to get id token --> if it fails --> Auth0 login window
    
    // if step 1 failed, is there a saved email?
    if !loggedIn, Defaults[.auth0Email] != "" {

      // YES, try to get a Refresh Token from the Keychain
      if let refreshToken = Keychain.get(kService, account: Defaults[.auth0Email]) {
        
        // can we get an Id Token from the Refresh Token?
        if let refreshedIdToken = getIdTokenFromRefreshToken(refreshToken) {
          
          // YES, save the token
          idToken = refreshedIdToken
          loggedIn = true

        } else {
          
          // NO, delete the refresh token and email (no longer valid)
          Defaults[.auth0Email] = ""
          Keychain.delete(kService, account: Defaults[.auth0Email])
        }
      }
    }
    // exit if not logged in
    guard loggedIn else { return }
    
    // we're logged in, get the picture
    do {
      
      // try to get the JSON Web Token
      let jwt = try decode(jwt: idToken)
      
      // get the Log On picture (if any)
      let claim = jwt.claim(name: kClaimPicture)
      if let gravatar = claim.string, let url = URL(string: gravatar) {
        
        setGravatarFrom(url: url)
      }
      
    } catch let error as NSError {
      
      // log the error
      _api.log.msg("Error decoding JWT token: \(error.localizedDescription)", level: .error, function: #function, file: #file, line: #line)
    }
    
    // connect to SmartLink server
    connectWanServer(token: idToken)
    
    // toggle the button title
    _loginButton.title = kLogoutTitle
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Close menu item
  ///
  /// - Parameter sender:     the button
  ///
  @IBAction func terminate(_ sender: AnyObject) {
    
    _delegate?.closeRadioPicker()
    _delegate?.terminateApp()
  }
  /// Respond to the Close button
  ///
  /// - Parameter sender: the button
  ///
  @IBAction func closeButton(_ sender: AnyObject) {
    
    // diconnect from WAN server
    _wanServer?.disconnect()
    
    // close this view & controller
    _delegate?.closeRadioPicker()
  }
  /// Respond to the Select button
  ///
  /// - Parameter _: the button
  ///
  @IBAction func selectButton( _: AnyObject ) {
    
    openClose(lowBW: Defaults[.useLowBw])
  }
  /// Respond to the Login button
  ///
  /// - Parameter _: the button
  ///
  @IBAction func loginButton(_ sender: NSButton) {
    
    logInOut()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Open or Close the selected Radio
  ///
  /// - Parameter lowBW: open the remote radio with low bandwith settings
  ///
  private func openClose(lowBW: Bool = false) {
    
    if _selectButton.title == kConnectTitle {
      // RadioPicker sheet will close & Radio will be opened
      
      _selectedRadio?.lowBandwidthConnect = lowBW
      
      getAuthentificationForRadio(_selectedRadio)

    } else {
      // RadioPicker sheet will remain open & Radio will be disconnected
      
      // tell the delegate to disconnect
      _delegate?.closeRadio()
      
      // toggle the button title
      _selectButton.title = kConnectTitle
    }
  }
  /// Start the process to get Authentifictaion for radio connection
  ///
  /// - Parameter radio: Radio to connect to
  ///
  private func getAuthentificationForRadio(_ radio: RadioParameters?) {
    
    if let radio = radio {
      
      // is a "Hole Punch" required?
      if radio.requiresHolePunch {
        // TODO: handle hole punch port

      } else {
        // NO
        radio.negotiatedHolePunchPort = 0
      }
      // ???
      _wanServer?.sendConnectMessageForRadio(radioSerial: radio.serialNumber, holePunchPort: radio.negotiatedHolePunchPort)
    }
  }
  /// Login or Logout to Auth0
  ///
  /// - Parameter open: Open/Close
  ///
  private func logInOut() {
    
    if _loginButton.title == kLoginTitle {
      
      // Login to auth0
      // get an instance of Auth0 controller
      _auth0ViewController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Auth0Login")) as? Auth0ViewController
      
      // make this View Controller the delegate of the Auth0 controller
      _auth0ViewController!.representedObject = self
      
      // show the Auth0 sheet
      presentViewControllerAsSheet(_auth0ViewController!)

    } else {
      // logout from the actual auth0 account
      // remove refresh token from keychain and email from defaults
      
      if Defaults[.auth0Email] != "" {
        
        Keychain.delete(kService, account: Defaults[.auth0Email])
        Defaults[.auth0Email] = ""
      }
      
      // clear tableview
      _availableRemoteRadios.removeAll()
      reload()
      
      // disconnect with Smartlink server
      _wanServer?.disconnect()
      
      _loginButton.title = kLoginTitle
      _nameLabel.stringValue = ""
      _callLabel.stringValue = ""
    }
  }
  /// Reload the Radio table
  ///
  private func reload() {
    
    DispatchQueue.main.async { [unowned self] in
      self._radioTableView.reloadData()
    }
  }
  
  /// Connect to the Wan Server
  ///
  /// - Parameter token:                token
  ///
  private func connectWanServer(token: String) {
    
    // instantiate a WanServer instance
    _wanServer = WanServer(delegate: self)
    
    // clear the reply table
    _delegate?.clearTable()

    // connect with pinger to avoid the SmartLink server to disconnect if we take too long (>30s)
    // to select and connect to a radio
    if (_wanServer?.connect(appName: kClientName, platform: kPlatform, token: token, ping: true)) != nil {
      
      // log success
      _api.log.msg("Connected to SmartLink Server", level: .info, function: #function, file: #file, line: #line)

    } else {
      
      // log the error
      _api.log.msg("Error connecting to SmartLink Server", level: .warning, function: #function, file: #file, line: #line)
    }
  }
  /// Given a Refresh Token attempt to get a Token
  ///
  /// - Parameter refreshToken:         a Refresh Token
  /// - Returns:                        a Token (if any)
  ///
  private func getIdTokenFromRefreshToken(_ refreshToken: String) -> String? {
    
    // guard that the token isn't empty
    guard refreshToken != "" else { return nil }
    
    // build a URL Request
    let url = URL(string: kAuth0Delegation)
    var urlRequest = URLRequest(url: url!)
    urlRequest.httpMethod = kHttpPost
    urlRequest.addValue(kApplicationJson, forHTTPHeaderField: kHttpHeaderField)
    
    // guard that body data was created
    guard let bodyData = createBodyData(refreshToken: refreshToken) else { return "" }
    
    // update the URL Request and retrieve the data
    urlRequest.httpBody = bodyData
    let (responseData, _, error) = URLSession.shared.synchronousDataTask(with: urlRequest)
    
    // guard that the data isn't empty and that no error occurred
    guard let data = responseData, error == nil else {
      
      // log the error
      _api.log.msg("Error retrieving id token token: \(error?.localizedDescription ?? "")", level: .error, function: #function, file: #file, line: #line)
      return nil
    }
    
    // is there a Token?
    if let token = parseTokenResponse(data: data) {
      // YES,return it
      return token
    }
    // NO token
    return nil
  }
  /// Create the Body Data for use in a URLSession
  ///
  /// - Parameter refreshToken:     a Refresh Token
  /// - Returns:                    the Data (if created)
  ///
  private func createBodyData(refreshToken: String) -> Data? {
    
    // guard that the Refresh Token isn't empty
    guard refreshToken != "" else { return nil }
    
    // create & populate the dictionary
    var dict = [String : String]()
    dict[kKeyClientId] = Auth0ViewController.kClientId
    dict[kKeyGrantType] = kGrantType
    dict[kKeyRefreshToken] = refreshToken
    dict[kKeyTarget] = Auth0ViewController.kClientId
    dict[kKeyScope] = kScope

    // try to obtain the data
    do {
      
      let data = try JSONSerialization.data(withJSONObject: dict)
      // success
      return data

    } catch _ {
      // failure
      return nil
    }
  }
  /// Parse the URLSession data
  ///
  /// - Parameter data:               a Data
  /// - Returns:                      a Token (if any)
  ///
  private func parseTokenResponse(data: Data) -> String? {
    
    do {
      // try to parse
      let myJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      
      // was something returned?
      if let parseJSON = myJSON {
        
        // YES, does it have a Token?
        if let  idToken = parseJSON[kKeyIdToken] as? String {
          // YES, retutn it
          return idToken
        }
      }
      // nothing returned
      return nil
      
    } catch _ {
      // parse error
      return nil
    }
  }
  /// Set the Log On image
  ///
  /// - Parameter url:                  the URL of the image
  ///
  private func setGravatarFrom(url: URL) {
    
    // get the image
    let image = NSImage(contentsOf: url)
    _gravatarView.image = image
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - WanServer Delegate methods
  
  /// Received radio list from server
  ///
  func wanRadioListReceived(wanRadioList: [RadioParameters]) {
    
    // relaod to display the updated list
    _availableRemoteRadios = wanRadioList
    reload()
  }
  /// Received user settings from server
  ///
  /// - Parameter userSettings:         a USer Setting struct
  ///
  func wanUserSettings(_ userSettings: WanUserSettings) {
    
    DispatchQueue.main.async { [unowned self] in
      
      self._nameLabel.stringValue = userSettings.firstName + " " + userSettings.lastName
      self._callLabel.stringValue = userSettings.callsign
    }
  }
  /// Radio is ready to connect
  ///
  /// - Parameters:
  ///   - handle:                       a Radio handle
  ///   - serial:                       a Radio Serial Number
  ///
  func wanRadioConnectReady(handle: String, serial: String) {
    
    DispatchQueue.main.async { [unowned self] in
      
      // does the Serial Number match?
      if self._selectedRadio?.serialNumber == serial {

        // YES, tell the delegate to connect to the selected Radio
        if !(self._delegate?.openRadio(self._selectedRadio, isWan: true, wanHandle: handle) ?? false ) {

          // log the event
          self._api.log.msg("Open remote radio \(self._selectedRadio?.name ?? "") not successful", level: .error, function: #function, file: #file, line: #line)
        }
        
      } else {
        
        // log the error
        self._api.log.msg("Unexpected serial number mismatch in wanRadioConnectReady()", level: .error, function: #function, file: #file, line: #line)
      }
    }
  }
  
  /// Received Wan test results
  ///
  func wanTestConnectionResultsReceived(results: WanTestConnectionResults) {
    
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Auth0 controller Delegate methods
  
  /// Close this sheet
  ///
  func closeAuth0Sheet() {
    
    if _auth0ViewController != nil { dismissViewController(_auth0ViewController!) }
    _auth0ViewController = nil
  }
  /// Set the id and refresh token
  ///
  /// - Parameters:
  ///   - idToken:        id Token string
  ///   - refreshToken:   refresh Token string
  ///
  func setTokens(idToken: String, refreshToken: String) {
    var expireDate = Date()
    
    do {
      
      // try to get the JSON Web Token
      let jwt = try decode(jwt: idToken)
      
      // save the Log On email (if any)
      var claim = jwt.claim(name: kClaimEmail)
      if let email = claim.string {
        
        // YES, save in user defaults
        Defaults[.auth0Email] = email
        
        // save refresh token in keychain
        Keychain.set(kService, account: email, data: refreshToken)
      }
      
      // save the Log On picture (if any)
      claim = jwt.claim(name: kClaimPicture)
      if let gravatar = claim.string, let url = URL(string: gravatar) {
        
        setGravatarFrom(url: url)
      }
      // get the expiry date (if any)
      if let expiresAt = jwt.expiresAt {
        expireDate = expiresAt
      }

    } catch let error as NSError {
      
      // log the error & exit
      _api.log.msg("Error decoding JWT token: \(error.localizedDescription)", level: .error, function: #function, file: #file, line: #line)
      return
    }
    
    // we have logged in so set the login button title
    DispatchQueue.main.async { [unowned self] in
      
      self._loginButton.title = self.kLogoutTitle
    }
    
    // save id token with expiry date
    _delegate?.token = Token(value: idToken, expiresAt: expireDate)

    // connect to SmartLink server
    connectWanServer(token: idToken)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView DataSource methods
  
  /// Tableview numberOfRows delegate method
  ///
  /// - Parameter aTableView:     the Tableview
  /// - Returns:                  number of rows
  ///
  func numberOfRows(in aTableView: NSTableView) -> Int {
    
    // get the number of rows
    return _availableRemoteRadios.count
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView Delegate methods
  
  /// Tableview view delegate method
  ///
  /// - Parameters:
  ///   - tableView:              the Tableview
  ///   - tableColumn:            a Tablecolumn
  ///   - row:                    the row number
  /// - Returns:                  an NSView
  ///
  func tableView( _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
    // get a view for the cell
    let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
    
    // is it the Upnp field?
    if tableColumn!.identifier.rawValue == kUpnpIdentifier {
      
      // YES
      let upnpEnabled = _availableRemoteRadios[row].upnpSupported
      view.textField!.stringValue = (upnpEnabled ? "YES" : "")
      
    } else {
      
      // NO, all other fields, set the stringValue of the cell's text field to the appropriate field
      view.textField!.stringValue = _availableRemoteRadios[row].valueForName(tableColumn!.identifier.rawValue) ?? ""
    }
    return view
  }
  /// Tableview selection change delegate method
  ///
  /// - Parameter notification:   notification object
  ///
  func tableViewSelectionDidChange(_ notification: Notification) {
    
    // A row must be selected to enable the buttons
    _selectButton.isEnabled = (_radioTableView.selectedRow >= 0)
    
    // is a row is selected?
    if _radioTableView.selectedRow >= 0 {
      
      // YES, a row is selected
      _selectedRadio = _availableRemoteRadios[_radioTableView.selectedRow]
      
      // set the "select button" title appropriately
      var isActive = false
      if let activeRadio = _api.activeRadio {
        isActive = ( activeRadio == _availableRemoteRadios[_radioTableView.selectedRow] && (_api.isWan) )
      }
      _selectButton.title = (isActive ? kDisconnectTitle : kConnectTitle)
      
    } else {
      
      // NO, no row is selected, set the button titles
      _selectButton.title = kConnectTitle
    }
  }
}
