//
//  EpisodeViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return 5
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! EpisodeCellView
    return result
  }
}
