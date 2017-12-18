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
  
  var downloadManager: DownloadManager?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    downloadManager = Library.global.downloadManager
  }
  
  @objc func reloadView() {
    tableView.reloadData()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    guard let manager = downloadManager else {
      return 0
    }
    
    return manager.queueCount
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let manager = downloadManager else { return nil }
    
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! DownloadCellView
    result.download = manager.downloads[row]
    
    return result
  }
  
  func downloadStarted() {
    tableView.reloadData()
  }
  
  func downloadFinished() {
    tableView.reloadData()
  }
}
