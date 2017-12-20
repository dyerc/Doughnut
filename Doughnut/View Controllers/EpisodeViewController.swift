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

enum EpisodeSortParameter {
  case EpisodeTitle
  case EpisodePubDate
}

enum EpisodeSortDirection {
  case Asc
  case Desc
}

class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
  var podcast: Podcast?
  var episodes = [Episode]()
  
  let sortParameter: EpisodeSortParameter = .EpisodePubDate
  let sortDirection: EpisodeSortDirection = .Desc
  
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
    
    tableView.registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
  }
  
  func reloadEpisodes() {
    if let podcast = podcast {
      episodes = podcast.episodes
      episodes.sort(by: { (a, b) -> Bool in
        switch sortParameter {
        case .EpisodePubDate:
          guard let aD = a.pubDate else { return false }
          guard let bD = b.pubDate else { return true }
          
          return aD.compare(bD) == .orderedAscending
        default:
          return (a.id ?? 0) < (b.id ?? 0)
        }
      })
      
      if sortDirection == .Desc {
        episodes.reverse()
      }
    }
    
    tableView.reloadData()
  }
  
  func reloadEpisode(_ episode: Episode) {
    if let index = episodes.index(where: { e -> Bool in
      e.id == episode.id
    }) {
      tableView.reloadData(forRowIndexes: IndexSet.init(integer: index), columnIndexes: IndexSet.init(integer: 0))
    }
  }
  
  func selectPodcast(_ selectedPodcast: Podcast?) {
    podcast = selectedPodcast
    reloadEpisodes()
  }
  
  @objc func podcastUpdated(_ notification: NSNotification) {
    if podcast?.id == notification.userInfo?["podcastId"] as? Int64 {
      reloadEpisodes()
    }
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return episodes.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! EpisodeCellView
    result.episode = episodes[row]
    
    return result
  }
  
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    viewController.selectEpisode(episode: episodes[row])
    return true
  }
  
  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
    return NSDragOperation.every
  }
  
  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
    guard let podcast = podcast else { return false }
    
    let pasteboard = info.draggingPasteboard()
    guard let items = pasteboard.pasteboardItems else { return true }
    
    var moveToLibrary = true
    let alert = NSAlert()
    alert.addButton(withTitle: "Copy to Library")
    alert.addButton(withTitle: "Link to Library")
    alert.addButton(withTitle: "Cancel")
    alert.messageText = "Copy these files into your Doughnut library?"
    
    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      moveToLibrary = true
    } else if result == .alertSecondButtonReturn {
      moveToLibrary = false
    } else {
      return false
    }
    
    for item in items {
      guard let stringURL = item.string(forType: NSPasteboard.PasteboardType(kUTTypeFileURL as String)) else { continue }
      guard let sourceURL = URL(string: stringURL) else { continue }
      
      if let episode = Episode.fromFile(podcast: podcast, url: sourceURL, copyToLibrary: moveToLibrary) {
        podcast.episodes.append(episode)
      }
    }
    
    Library.global.save(podcast: podcast)
    
    return true
  }
  
  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let episode = episodes[tableView.clickedRow]
    
    switch menuItem.title {
    case "Play Now":
      return true
    case "Mark as Played":
      return !episode.played
    case "Mark as Unplayed":
      return episode.played
    case "Mark as Favourite":
      return !episode.favourite
    case "Unmark Favourite":
      return episode.favourite
    case "Delete Episode":
      return true
    case "Download":
      return episode.enclosureUrl != nil && !episode.downloaded
    case "Move to Trash":
      return episode.downloaded
    case "Show Episode":
      return true
    case "Show in Finder":
      return episode.downloaded
    case "Mark all as Played":
      return true
    case "Mark all as Unplayed":
      return true
    default:
      return false
    }
  }
  
  @IBAction func episodeDoubleClicked(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    Player.global.play(episode: episode)
  }
  
  @IBAction func playNow(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    Player.global.play(episode: episode)
  }
  
  @IBAction func markAsPlayed(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    episode.played = true
    Library.global.save(episode: episode)
  }
  
  @IBAction func markAsUnplayed(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    episode.played = false
    Library.global.save(episode: episode)
  }
  
  @IBAction func markAsFavourite(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    episode.favourite = true
    Library.global.save(episode: episode)
  }
  
  @IBAction func unmarkAsFavourite(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    episode.favourite = false
    Library.global.save(episode: episode)
  }
  
  @IBAction func download(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    Library.global.downloadManager.queueDownload(episode: episode)
  }
  
  @IBAction func moveToTrash(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    episode.downloaded = false
    episode.fileName = nil
    Library.global.save(episode: episode)
  }
  
  @IBAction func deleteEpisode(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    guard let podcast = episode.podcast else { return }
    
    var moveToTrash = false
    if episode.downloaded {
      let alert = NSAlert()
      alert.addButton(withTitle: "Leave File(s)")
      alert.addButton(withTitle: "Move to Trash")
      alert.messageText = "Move File(s) to Trash"
      alert.informativeText = "Would you like to move this episode's downloaded file to the trash"
      
      let result = alert.runModal()
      if result == .alertFirstButtonReturn {
        moveToTrash = false
      } else {
        moveToTrash = true
      }
    }
    
    if moveToTrash {
      podcast.deleteEpisodeAndTrash(episode: episode)
    } else {
      podcast.deleteEpisode(episode: episode)
    }
  }
  
  @IBAction func showEpisode(_ sender: Any) {
    if let wc = windowController {
      let editWindow = wc.episodeWindowController
      let editController = editWindow.contentViewController as? EditEpisodeViewController
      editController?.episode = episodes[tableView.clickedRow]
      editWindow.showWindow(self)
    }
  }
  
  @IBAction func showInFinder(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    guard let podcast = episode.podcast else { return }

    NSWorkspace.shared.selectFile(episode.url()?.path, inFileViewerRootedAtPath: podcast.path)
  }
  
  @IBAction func markAllAsPlayed(_ sender: Any) {
    guard let podcast = episodes[tableView.clickedRow].podcast else { return }
    
    for episode in episodes {
      episode.played = true
    }
    
    Library.global.save(podcast: podcast)
  }
  
  @IBAction func markAllAsUnplayed(_ sender: Any) {
    guard let podcast = episodes[tableView.clickedRow].podcast else { return }
    
    for episode in episodes {
      episode.played = false
    }
    
    Library.global.save(podcast: podcast)
  }
}
