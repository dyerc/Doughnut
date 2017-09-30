//
//  EpisodeViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  var episodes = [Episode]()
  
  @IBOutlet var tableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(podcastSelected), name: ViewController.Events.PodcastSelected.notification, object: nil)
  }
  
  @objc func podcastSelected(_ notification: NSNotification) {
    if let podcast = notification.userInfo?["podcast"] as? Podcast {
      episodes = podcast.episodes
      tableView.reloadData()
    }
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return episodes.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! EpisodeCellView
    let episode = episodes[row]
    
    result.title.stringValue = episode.title
    result.summary.stringValue = episode.description ?? ""
    
    return result
  }
}
