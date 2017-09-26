//
//  PodcastViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  
  @IBOutlet var tableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return 5
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    return nil
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    
  }
  
}
