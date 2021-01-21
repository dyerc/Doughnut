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

enum PodcastSortParameter: String {
  case PodcastTitle = "Title"
  case PodcastEpisodes = "Episodes"
  case PodcastUnplayed = "Unplayed"
  case PodcastFavourites = "Favourited"
  case PodcastRecentEpisodes = "Recent Episode"
}

class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, SortingViewDelegate {
  var podcasts = [Podcast]()
  
  @IBOutlet var tableView: NSTableView!
  @IBOutlet var sortView: SortingView!
  
  var filter: GlobalFilter = .All {
    didSet {
      reloadPodcasts()
    }
  }
  
  var sortBy: PodcastSortParameter = .PodcastTitle {
    didSet {
      Preference.set(sortBy.rawValue, for: Preference.Key.podcastSortParam)
    }
  }
  
  var sortDirection: SortDirection = .Desc {
    didSet {
      Preference.set(sortDirection.rawValue, for: Preference.Key.podcastSortDirection)
    }
  }
  
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
    
    sortView.menuItemTitles = [
      PodcastSortParameter.PodcastTitle.rawValue,
      PodcastSortParameter.PodcastEpisodes.rawValue,
      PodcastSortParameter.PodcastFavourites.rawValue,
      PodcastSortParameter.PodcastRecentEpisodes.rawValue,
      PodcastSortParameter.PodcastUnplayed.rawValue
    ]
    
    if let sortPreference = Preference.string(for: Preference.Key.podcastSortParam), let sortParam = PodcastSortParameter(rawValue: sortPreference) {
      sortBy = sortParam
    }
    
    if Preference.string(for: Preference.Key.podcastSortDirection) == "Ascending" {
      sortDirection = .Asc
    } else {
      sortDirection = .Desc
    }
    
    sortView.sortParam = sortBy.rawValue
    sortView.sortDirection = sortDirection
    sortView.delegate = self
    
    reloadPodcasts()
  }
  
  func reloadPodcasts() {
    podcasts = Library.global.podcasts
    
    podcasts = podcasts.filter({ podcast -> Bool in
      if filter == .New {
        return podcast.unplayedCount > 0
      } else {
        return true
      }
    })
    
    // Sort into ascending order
    podcasts.sort { (a, b) -> Bool in
      switch sortBy {
      case .PodcastTitle:
        return a.title < b.title
      case .PodcastEpisodes:
        return a.episodes.count < b.episodes.count
      case .PodcastFavourites:
        return a.favouriteCount < b.favouriteCount
      case .PodcastUnplayed:
        return a.unplayedCount < b.unplayedCount
      case .PodcastRecentEpisodes:
        guard let aD = a.latestEpisode?.pubDate else { return false }
        guard let bD = b.latestEpisode?.pubDate else { return true }
        
        return aD < bD
      }
    }
    
    if sortDirection == .Desc {
      podcasts.reverse()
    }
    
    let selectedRow = tableView.selectedRow
    tableView.reloadData()
    tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
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
    result.loading = podcast.loading
    
    return result
  }
  
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    //NotificationCenter.default.post(name: ViewController.Events.PodcastSelected.notification, object: nil, userInfo: ["podcast": podcasts[row]])
    viewController.selectPodcast(podcast: podcasts[row])
    return true
  }
  
  func sorted(by: String?, direction: SortDirection) {
    if let sortParam = PodcastSortParameter(rawValue: by ?? "") {
      sortBy = sortParam
    }
    
    sortDirection = direction
    
    reloadPodcasts()
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
  
  @IBAction func markAllAsPlayed(_ sender: Any) {
    let podcast = podcasts[tableView.clickedRow]
    
    for episode in podcast.episodes {
      episode.played = true
    }
    
    // Manually trigger a view reload to make update seem instant
    viewController.libraryUpdatedPodcast(podcast: podcast)
    
    // Commit changes to library
    Library.global.save(podcast: podcast)
  }
  
  @IBAction func markAllAsUnplayed(_ sender: Any) {
    let podcast = podcasts[tableView.clickedRow]
    
    for episode in podcast.episodes {
      episode.played = false
    }
    
    // Manually trigger a view reload to make update seem instant
    viewController.libraryUpdatedPodcast(podcast: podcast)
    
    // Commit changes to library
    Library.global.save(podcast: podcast)
  }
  
  @IBAction func copyPodcastURL(_ sender: Any) {
    if let feed = podcasts[tableView.clickedRow].feed {
      NSPasteboard.general.declareTypes([.string], owner: nil)
      NSPasteboard.general.setString(feed, forType: .string)
    }
  }
  
  @IBAction func unsubscribe(_ sender: Any) {
    let podcast = podcasts[tableView.clickedRow]
    
    let alert = NSAlert()
    alert.addButton(withTitle: "Leave Files")
    alert.addButton(withTitle: "Move to Trash")
    alert.addButton(withTitle: "Cancel")
    alert.messageText = "Move Files to Trash"
    alert.informativeText = "Would you like to move any downloaded episodes to the trash?"
    
    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      Library.global.unsubscribe(podcast: podcast, removeFiles: false)
    } else if result == .alertSecondButtonReturn {
      Library.global.unsubscribe(podcast: podcast, removeFiles: true)
    }
  }
  
  @IBAction func refreshAll(_ sender: Any) {
    Library.global.reloadAll()
  }

  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if tableView.clickedRow < 0 && menuItem.title != "Refresh All" {
      return false
    }
    return true
  }
}
