//
//  WANRadioPickerViewController.swift
//  CommonCode
//
//  Created by Mario Illgen on 08.02.18.
//  Copyright © 2018 Mario Illgen. All rights reserved.
//

import Cocoa
import os.log
import xLib6000
import SwiftyUserDefaults

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
  private let _log                          = OSLog(subsystem: Api.kDomainId + "." + kClientName, category: "WanRadioPickerVC")
  private var _auth0ViewController          : Auth0ViewController?
  private var _availableRemoteRadios        = [RadioParameters]()           // Radios discovered
  private weak var _delegate                : RadioPickerDelegate? {
    return representedObject as? RadioPickerDelegate
  }
  private var _selectedRadio                : RadioParameters?              // Radio in selected row
  private var _wanServer                    : WanServer?
  private var _parentVc                     : NSViewController!

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

    // get a reference to the Tab view controller (the "presented" vc)
    _parentVc = parent!

    // TODO: put this on a background queue??
    // check if we have logged in into Auth0 and try to get a token using the refresh token from the Keychain

    // is there a saved Auth0 token which has not expired?
    if let previousIdToken = _delegate?.token, previousIdToken.isValidAtDate( Date()) {

      // YES, we are already logged into SmartLink, use the saved token
      loggedIn = true
      idToken = previousIdToken.value
    }
    
    // if not logged in at this point, is there a saved email to use for obtaining a refresh token?
    if !loggedIn, Defaults[.smartLinkAuth0Email] != "" {

      // YES, try to get a Refresh Token from our Keychain
      if let refreshToken = Keychain.get(kService, account: Defaults[.smartLinkAuth0Email]) {
        
        // can we get an Id Token from the Refresh Token?
        if let refreshedIdToken = getIdTokenFromRefreshToken(refreshToken) {
          
          // YES, now we are logged into SmartLink, use the saved token
          loggedIn = true
          idToken = refreshedIdToken

        } else {
          
          // NO, the refresh token and email are no longer valid, delete them
          Defaults[.smartLinkAuth0Email] = ""
          Keychain.delete(kService, account: Defaults[.smartLinkAuth0Email])
        }
      }
    }
    // exit if we are not logged in at this point (User will need to press the Log In button)
    guard loggedIn else { return }
    
    // we're logged in, get the User image (gravatar)
    do {
      
      // try to get the JSON Web Token
      let jwt = try decode(jwt: idToken)
      
      // get the Log On image (if any) from the token
      let claim = jwt.claim(name: kClaimPicture)
      if let gravatar = claim.string, let url = URL(string: gravatar) {
        
        setLogOnImage(from: url)
      }
      
    } catch let error as NSError {
      
      // log the error
      os_log("Error decoding JWT token: %{public}@", log: _log, type: .error, error.localizedDescription)
    }
    
    // connect to the SmartLink server
    connectWanServer(token: idToken)
    
    // change the button title
    _loginButton.title = kLogoutTitle
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Action methods
  
  /// Respond to the Quit menu item
  ///
  /// - Parameter sender:     the button
  ///
  @IBAction func quitRadio(_ sender: AnyObject) {
    
    _parentVc.dismiss(sender)
    
    // perform an orderly shutdown of all the components
    _api.shutdown(reason: .normal)
    
    DispatchQueue.main.async {
      os_log("Application closed by user", log: self._log, type: .info)
      
      NSApp.terminate(self)
    }
  }
  /// Respond to the Close button
  ///
  /// - Parameter sender:         the button
  ///
  @IBAction func closeButton(_ sender: AnyObject) {
    
//    // diconnect from WAN server
//    _wanServer?.disconnect()
    
    _parentVc.dismiss(sender)
  }
  /// Respond to the Select button
  ///
  /// - Parameter:                the button
  ///
  @IBAction func selectButton( _: AnyObject ) {
    
    // attempt to Open / Close the selected Radio
    openClose(lowBW: Defaults[.lowBandwidthEnabled])
  }
  /// Respond to the Login button
  ///
  /// - Parameter _: the button
  ///
  @IBAction func loginButton(_ sender: NSButton) {
    
    // Log In / Out of SmartLink
    logInOut()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Open or Close the selected Radio
  ///
  /// - Parameter lowBW: open the remote radio with low bandwith settings
  ///
  private func openClose(lowBW: Bool = false) {
    
    // Connect or Disconnect?
    if _selectButton.title == kConnectTitle {
      
      // CONNECT, RadioPicker sheet will close & Radio will be opened
      
      // is the selected radio in use, but not by this app?
      if _selectedRadio!.status == "In_Use" && _api.activeRadio == nil {
        
        // YES, ask the user to confirm closing it
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Disconnect Radio?"
        alert.informativeText = "Are you sure you want to disconnect the current radio session?"
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        // do nothing if closing is not confirmed by the user
        if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn { return }
      }
      _selectedRadio?.lowBandwidthConnect = lowBW
      
      getAuthentificationForRadio(_selectedRadio)

      DispatchQueue.main.async { [unowned self] in
        self.closeButton(self)
      }

    } else {
      
      // DISCONNECT, RadioPicker sheet will remain open & Radio will be disconnected
      
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
      _auth0ViewController = storyboard!.instantiateController(withIdentifier: "Auth0Login") as? Auth0ViewController
//      _auth0ViewController!.view.translatesAutoresizingMaskIntoConstraints = false

      // make this View Controller the delegate of the Auth0 controller
      _auth0ViewController!.representedObject = self
      
      // show the Auth0 sheet
      presentAsSheet(_auth0ViewController!)

    } else {
      // logout from the actual auth0 account
      // remove refresh token from keychain and email from defaults
      
      if Defaults[.smartLinkAuth0Email] != "" {
        
        Keychain.delete(kService, account: Defaults[.smartLinkAuth0Email])
        Defaults[.smartLinkAuth0Email] = ""
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
    
//    // clear the reply table
//    _delegate?.clearTable()

    // connect with pinger to avoid the SmartLink server to disconnect if we take too long (>30s)
    // to select and connect to a radio
    if !_wanServer!.connect(appName: kClientName, platform: kPlatform, token: token, ping: true) {
      
      // log the error
      os_log("Error connecting to SmartLink Server", log: _log, type: .default)
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
      os_log("Error retrieving id token token: %{public}@", log: _log, type: .error, error?.localizedDescription ?? "")

      return nil
    }
    
    // is there a Token?
    if let token = parseTokenResponse(data: data) {
      do {
        
        let jwt = try decode(jwt: token)
        
        // validate id token; see https://auth0.com/docs/tokens/id-token#validate-an-id-token
        if !isJWTValid(jwt) {
          // log the error
          os_log("JWT token not valid", log: _log, type: .error)
          
          return nil
        }
        
      } catch let error as NSError {
        // log the error
        os_log("Error decoding JWT token: %{public}@", log: _log, type: .error, error.localizedDescription)
        
        return nil
      }
      
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
  private func setLogOnImage(from url: URL) {
    
    // get the image
    let image = NSImage(contentsOf: url)
    _gravatarView.image = image
  }
  /// check if a JWT token is valid
  ///
  /// - Parameter jwt:                  a JWT token
  /// - Returns:                        valid / invalid
  ///
  private func isJWTValid(_ jwt: JWT) -> Bool {
    // see: https://auth0.com/docs/tokens/id-token#validate-an-id-token
    // validate only the claims
    
    // 1.
    // Token expiration: The current date/time must be before the expiration date/time listed in the exp claim (which
    // is a Unix timestamp).
    guard let expiresAt = jwt.expiresAt, Date() < expiresAt else { return false }
    
    // 2.
    // Token issuer: The iss claim denotes the issuer of the JWT. The value must match the the URL of your Auth0
    // tenant. For JWTs issued by Auth0, iss holds your Auth0 domain with a https:// prefix and a / suffix:
    // https://YOUR_AUTH0_DOMAIN/.
    var claim = jwt.claim(name: "iss")
    guard let domain = claim.string, domain == Auth0ViewController.kAuth0Domain else { return false }
    
    // 3.
    // Token audience: The aud claim identifies the recipients that the JWT is intended for. The value must match the
    // Client ID of your Auth0 Client.
    claim = jwt.claim(name: "aud")
    guard let clientId = claim.string, clientId == Auth0ViewController.kClientId else { return false }
    
    return true
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
          os_log("Open remote radio FAILED: %{public}@ @ %{public}@", log: self._log, type: .error, self._selectedRadio!.nickname, self._selectedRadio!.publicIp)
        }
        
      } else {
        
        // log the error
        os_log("Unexpected serial number mismatch in wanRadioConnectReady(), %{public}@ vs %{public}@", log: self._log, type: .error, self._selectedRadio!.serialNumber, serial)
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
    
    if _auth0ViewController != nil { dismiss(_auth0ViewController!) }
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
      
      // validate id token; see https://auth0.com/docs/tokens/id-token#validate-an-id-token
      if !isJWTValid(jwt) {
        
        os_log("JWT token not valid", log: _log, type: .error)

        return
      }
      // save the Log On email (if any)
      var claim = jwt.claim(name: kClaimEmail)
      if let email = claim.string {
        
        // YES, save in user defaults
        Defaults[.smartLinkAuth0Email] = email
        
        // save refresh token in keychain
        Keychain.set(kService, account: email, data: refreshToken)
      }
      
      // save the Log On picture (if any)
      claim = jwt.claim(name: kClaimPicture)
      if let gravatar = claim.string, let url = URL(string: gravatar) {
        
        setLogOnImage(from: url)
      }
      // get the expiry date (if any)
      if let expiresAt = jwt.expiresAt {
        expireDate = expiresAt
      }

    } catch let error as NSError {
      
      // log the error & exit
      os_log("Error decoding JWT token: %{print}@", log: _log, type: .error, error.localizedDescription)

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
      view.textField!.stringValue = _availableRemoteRadios[row].valueForName(tableColumn!.identifier.rawValue)
    }
    view.toolTip = _availableRemoteRadios[row].description
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
