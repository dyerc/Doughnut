//
//  EpisodeViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

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
  
  override func viewDidLoad() {
    super.viewDidLoad()
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
    case "Download":
      return episode.enclosureUrl != nil && !episode.downloaded
    case "Move to Trash":
      return episode.downloaded
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
  
  @IBAction func showInFinder(_ sender: Any) {
    let episode = episodes[tableView.clickedRow]
    guard let fileName = episode.fileName else { return }
    guard let podcast = episode.podcast else { return }

    NSWorkspace.shared.selectFile("\(podcast.path)/\(fileName)", inFileViewerRootedAtPath: podcast.path)
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
