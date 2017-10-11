//
//  DownloadsViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 11/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class DownloadsViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  @IBOutlet weak var tableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(reloadView), name: Library.Events.Downloading.notification, object: nil)
  }
  
  @objc func reloadView() {
    tableView.reloadData()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return Library.global.downloads.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! DownloadCellView
    result.download = Library.global.downloads[row]
    
    return result
  }
}
