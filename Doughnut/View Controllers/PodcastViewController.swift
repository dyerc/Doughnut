/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Cocoa

class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  var podcasts = [Podcast]()
  
  @IBOutlet var tableView: NSTableView!
  
  var viewController: ViewController {
    get {
      return parent as! ViewController
    }
  }
  
  var windowController: WindowController? {
    get {
      guard let window = NSApplication.shared.windows.first else { return nil }
      return window.windowController as? WindowController
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
    result.podcastUnplayedCount.value = podcast.unplayedCount
    
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
  
  @IBAction func podcastInfo(_ sender: Any) {
    if let wc = windowController {
      let infoWindow = wc.podcastWindowController
      let infoController = infoWindow.contentViewController as? ShowPodcastViewController
      infoController?.podcast = podcasts[tableView.clickedRow]
      infoWindow.showWindow(self)
    }
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
