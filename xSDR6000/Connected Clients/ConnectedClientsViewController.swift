//
//  ConnectedClientsViewController.swift
//  xSDR6000
//
//  Created by Douglas Adams on 4/19/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Cocoa
import xLib6000

class ConnectedClientsViewController            : NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @IBOutlet private weak var _tableView         : NSTableView!
  
  private let _log                              = NSApp.delegate as! AppDelegate
  private var _guiClients                       = [GuiClient]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Overridden Methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addNotifications()
  }
  
  override func viewWillAppear() {
    view.window!.level = .floating
  }

  // ----------------------------------------------------------------------------
  // MARK: - Notification Methods
  
  /// Add subsciptions to Notifications
  ///     (as of 10.11, subscriptions are automatically removed on deinit when using the Selector-based approach)
  ///
  private func addNotifications() {
    
    NC.makeObserver(self, with: #selector(guiClientHasBeenAdded(_:)), of: .guiClientHasBeenAdded)
//    NC.makeObserver(self, with: #selector(guiClientHasBeenUpdated(_:)), of: .guiClientHasBeenUpdated)
    NC.makeObserver(self, with: #selector(guiClientHasBeenRemoved(_:)), of: .guiClientHasBeenRemoved)
  }
  /// Process guiClientHasBeenAdded Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func guiClientHasBeenAdded(_ note: Notification) {
    
    if let guiClient = note.object as? GuiClient {
      _guiClients.append(guiClient)
      
      DispatchQueue.main.async { [weak self] in
        self?._tableView.reloadData()
      }
    }
  }
  /// Process guiClientHasBeenUpdated Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
//  @objc private func guiClientHasBeenUpdated(_ note: Notification) {
//
//    if let guiClient = note.object as? GuiClient {
//      if let index = _guiClients.firstIndex(of: guiClient) {
//        _guiClients[index] = guiClient
//
//        DispatchQueue.main.async { [weak self] in
//          self?._tableView.reloadData()
//        }
//      }
//    }
//  }
  /// Process guiClientHasBeenRemoved Notification
  ///
  /// - Parameter note:       a Notification instance
  ///
  @objc private func guiClientHasBeenRemoved(_ note: Notification) {
    
    if let guiClient = note.object as? GuiClient {
      if let index = _guiClients.firstIndex(of: guiClient) {
        _guiClients.remove(at: index)
        
        DispatchQueue.main.async { [weak self] in
          self?._tableView.reloadData()
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView DataSource methods
  
  ///
  ///
  /// - Parameter aTableView: the TableView
  /// - Returns:              number of rows
  ///
  public func numberOfRows(in aTableView: NSTableView) -> Int {
    
    return _guiClients.count
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - NSTableView Delegate methods
  
  /// Return a view to be used for the row/column
  ///
  /// - Parameters:
  ///   - tableView:          the TableView
  ///   - tableColumn:        the current TableColumn
  ///   - row:                the current row number
  /// - Returns:              the view for the column & row
  ///
  public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    
    // get a view for the cell
    let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner:self) as! NSTableCellView
    //    view.toolTip =
    //    """
    //    Host:\t\t\(_guiClients[row].host)
    //    Ip:\t\t\(_guiClients[row].ip)
    //    """
    
    // set the text
    switch tableColumn!.identifier.rawValue {
      
    case "Handle":
      view.textField!.stringValue = _guiClients[row].handle.hex
    case "Station":
      view.textField!.stringValue = _guiClients[row].station
    case "Program":
      view.textField!.stringValue = _guiClients[row].program
    case "ClientId":
      view.textField!.stringValue = _guiClients[row].clientId ?? ""
    default:
      _log.msg("Unknown table column: \(tableColumn!.identifier.rawValue)", level: .error, function: #function, file: #file, line: #line)
    }
    return view
  }
}
