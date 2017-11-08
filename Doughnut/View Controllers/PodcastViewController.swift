//
//  PodcastViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  var podcasts = [Podcast]()
  
  @IBOutlet var tableView: NSTableView!
  
  var viewController: ViewController {
    get {
      return parent as! ViewController
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    reloadPodcasts()
  }
  
  func reloadPodcasts() {
    podcasts = Library.global.podcasts
    tableView.reloadData()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return podcasts.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let podcast = podcasts[row]
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! PodcastCellView
    
    result.title.stringValue = podcast.title
    result.author.stringValue = podcast.author ?? ""
    
    if podcast.image != nil && podcast.image!.isValid {
      result.imageView?.image = podcast.image
    } else {
      result.imageView?.image = NSImage(named: NSImage.Name(rawValue: "PodcastPlaceholder"))
    }
    
    result.episodeCount.stringValue = "\(podcast.episodes.count) episodes"
    
    if podcast.loading {
      result.progressIndicator.startAnimation(self)
      result.progressIndicator.isHidden = false
      result.episodeCount.isHidden = true
    } else {
      result.progressIndicator.stopAnimation(self)
      result.progressIndicator.isHidden = true
      result.episodeCount.isHidden = false
    }
    
    return result
  }
  
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    //NotificationCenter.default.post(name: ViewController.Events.PodcastSelected.notification, object: nil, userInfo: ["podcast": podcasts[row]])
    viewController.selectPodcast(podcast: podcasts[row])
    return true
  }
  
  @IBAction func reloadPodcast(_ sender: Any) {
    Library.global.reload(podcast: podcasts[tableView.clickedRow])
  }
  
  @IBAction func copyPodcastURL(_ sender: Any) {
    if let feed = podcasts[tableView.clickedRow].feed {
      NSPasteboard.general.declareTypes([.string], owner: nil)
      NSPasteboard.general.setString(feed, forType: .string)
    }
  }
  
  @IBAction func unsubscribe(_ sender: Any) {
  }
  
  @IBAction func refreshAll(_ sender: Any) {
  }
  
}
