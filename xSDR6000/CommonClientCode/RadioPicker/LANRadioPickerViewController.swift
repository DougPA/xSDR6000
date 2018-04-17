
//  RadioPickerViewController.swift
//  CommonCode
//
//  Created by Mario Illgen on 13.01.17.
//  Copyright © 2017 Mario Illgen. All rights reserved.
//
//  Originally Created by Douglas Adams on 5/21/15.

import Cocoa
import xLib6000
import SwiftyUserDefaults

//#if XSDR6000
//  import xLib6000
//#endif

// --------------------------------------------------------------------------------
// MARK: - LAN RadioPicker Delegate definition
// --------------------------------------------------------------------------------

protocol LANRadioPickerDelegate: class {
  
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
  func openRadio(_ radio: RadioParameters?, remote: Bool, handle: String ) -> Bool
  
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
// MARK: - RadioPicker View Controller class implementation
// --------------------------------------------------------------------------------

final class LANRadioPickerViewController    : NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private var _radioTableView     : NSTableView!                // table of Radios
  @IBOutlet private var _selectButton       : NSButton!                   // Connect / Disconnect
  @IBOutlet private var _defaultButton      : NSButton!                   // Set as default
  
  private var _api                          = Api.sharedInstance
  private var _selectedRadio                : RadioParameters?            // Radio in selected row
  
  private weak var _delegate                : RadioPickerDelegate? {
    return representedObject as? RadioPickerDelegate
  }

  // constants
  private let kColumnIdentifierDefaultRadio = "defaultRadio"
  private let kConnectTitle                 = "Connect"
  private let kDisconnectTitle              = "Disconnect"
  private let kSetAsDefault                 = "Set as Default"
  private let kClearDefault                 = "Clear Default"
  private let kDefaultFlag                  = "YES"
  
  // ----------------------------------------------------------------------------
  // MARK: - Overriden methods
  
  /// the View has loaded
  ///
  override func viewDidLoad() {
    
    super.viewDidLoad()

    // allow the User to double-click the desired Radio
    _radioTableView.doubleAction = #selector(LANRadioPickerViewController.selectButton(_:))
    
    _selectButton.title = kConnectTitle

    addNotifications()
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
  /// Respond to the Default button
  ///
  /// - Parameter sender: the button
  ///
  @IBAction func defaultButton(_ sender: NSButton) {
    
    // save the selection
    let selectedRow = _radioTableView.selectedRow
    
    // Clear / Set the Default
    if sender.title == kClearDefault {
      
      Defaults[.defaultsDictionary] = RadioParameters().dictFromParams()
      
    } else {
      
      Defaults[.defaultsDictionary] = _api.availableRadios[selectedRow].dictFromParams()
    }
    
    // to display the Default status
    _radioTableView.reloadData()
    
    // restore the selection
    _radioTableView.selectRowIndexes(IndexSet(integersIn: selectedRow..<selectedRow+1), byExtendingSelection: true)
    
  }
  /// Respond to the Close button
  ///
  /// - Parameter sender: the button
  ///
  @IBAction func closeButton(_ sender: AnyObject) {

    // close this view & controller
    _delegate?.closeRadioPicker()
  }
  /// Respond to the Select button
  ///
  /// - Parameter _: the button
  ///
  @IBAction func selectButton( _: AnyObject ) {
    
    openClose()
  }
  /// Respond to a double-clicked Table row
  ///
  /// - Parameter _: the row clicked
  ///
  func doubleClick(_: AnyObject) {
    
    openClose()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Open or Close the selected Radio
  ///
  /// - Parameter open: Open/Close
  ///
  private func openClose() {
    
    if _selectButton.title == kConnectTitle {
      // RadioPicker sheet will close & Radio will be opened
      
      _delegate?.clearTable()
      
      // tell the delegate to connect to the selected Radio
      let _ = _delegate?.openRadio(_selectedRadio, isWan: false, wanHandle: "")

    } else {
      // RadioPicker sheet will remain open & Radio will be disconnected
      
      // tell the delegate to disconnect
      _delegate?.closeRadio()
      _selectButton.title = kConnectTitle
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subscriptions to Notifications
  ///
  private func addNotifications() {
    
    // Available Radios changed
    NC.makeObserver(self, with: #selector(radiosAvailable(_:)), of: .radiosAvailable, object: nil)
  }
  /// Process .radiosAvailable Notification
  ///
  /// - Parameter note: a Notification instance
  ///
  @objc private func radiosAvailable(_ note: Notification) {
    
    DispatchQueue.main.async { [unowned self] in
      
      self._radioTableView.reloadData()
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView DataSource methods
  
  /// Tableview numberOfRows delegate method
  ///
  /// - Parameter aTableView: the Tableview
  /// - Returns: number of rows
  ///
  func numberOfRows(in aTableView: NSTableView) -> Int {
    
    // get the number of rows
    return _api.availableRadios.count
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView Delegate methods
  
  /// Tableview view delegate method
  ///
  /// - Parameters:
  ///   - tableView: the Tableview
  ///   - tableColumn: a Tablecolumn
  ///   - row: the row number
  /// - Returns: an NSView
  ///
  func tableView( _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
    // get a view for the cell
    let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
    
    // what field?
    if tableColumn!.identifier.rawValue == kColumnIdentifierDefaultRadio {
      
      // is this row the default?
      let defaultRadio = RadioParameters( Defaults[.defaultsDictionary] )
      view.textField!.stringValue = (defaultRadio == _api.availableRadios[row] ? kDefaultFlag : "")
      
    } else {
      
      // all other fields, set the stringValue of the cell's text field to the appropriate field
      view.textField!.stringValue = _api.availableRadios[row].valueForName(tableColumn!.identifier.rawValue) ?? ""
    }
    return view
  }
  /// Tableview selection change delegate method
  ///
  /// - Parameter notification: notification object
  ///
  func tableViewSelectionDidChange(_ notification: Notification) {
    
    // A row must be selected to enable the buttons
    _selectButton.isEnabled = (_radioTableView.selectedRow >= 0)
    _defaultButton.isEnabled = (_radioTableView.selectedRow >= 0)
    
    if _radioTableView.selectedRow >= 0 {
      
      // a row is selected
      _selectedRadio = _api.availableRadios[_radioTableView.selectedRow]
      
      // set "default button" title appropriately
      let defaultRadio = RadioParameters( Defaults[.defaultsDictionary] )
      _defaultButton.title = (defaultRadio == _api.availableRadios[_radioTableView.selectedRow] ? kClearDefault : kSetAsDefault)
      
      // set the "select button" title appropriately
      var isActive = false
      if let activeRadio = _api.activeRadio {
        isActive = ( activeRadio == _api.availableRadios[_radioTableView.selectedRow] )
      }
      _selectButton.title = (isActive ? kDisconnectTitle : kConnectTitle)
      
    } else {
      
      // no row is selected, set the button titles
      _defaultButton.title = kSetAsDefault
      _selectButton.title = kConnectTitle
    }
  }
}
