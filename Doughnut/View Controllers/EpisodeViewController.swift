//
//  EpisodeViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
  var podcast: Podcast?
  
  @IBOutlet var tableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(podcastSelected), name: ViewController.Events.PodcastSelected.notification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(podcastUpdated), name: Library.Events.PodcastUpdated.notification, object: nil)
  }
  
  @objc func podcastSelected(_ notification: NSNotification) {
    if let selectedPodcast = notification.userInfo?["podcast"] as? Podcast {
      podcast = selectedPodcast
      tableView.reloadData()
    }
  }
  
  @objc func podcastUpdated(_ notification: NSNotification) {
    if podcast?.id == notification.userInfo?["podcastId"] as? Int64 {
      tableView.reloadData()
    }
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    guard let podcast = podcast else { return 0 }
    return podcast.episodes.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let podcast = podcast else { return nil }
    
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! EpisodeCellView
    result.episode = podcast.episodes[row]
    
    return result
  }
  
  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let podcast = podcast else { return false }
    let episode =  podcast.episodes[tableView.clickedRow]
    
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
    default:
      return false
    }
  }
  
  @IBAction func playNow(_ sender: Any) {
    if let episode = podcast?.episodes[tableView.clickedRow] {
      Player.global.play(episode: episode)
    }
  }
  
  @IBAction func markAsPlayed(_ sender: Any) {
    if let episode = podcast?.episodes[tableView.clickedRow] {
      episode.played = true
      Library.global.save(episode: episode)
    }
  }
  
  @IBAction func markAsUnplayed(_ sender: Any) {
    if let episode = podcast?.episodes[tableView.clickedRow] {
      episode.played = false
      Library.global.save(episode: episode)
    }
  }
  
  @IBAction func markAsFavourite(_ sender: Any) {
    if let episode = podcast?.episodes[tableView.clickedRow] {
      episode.favourite = true
      Library.global.save(episode: episode)
    }
  }
  
  @IBAction func unmarkAsFavourite(_ sender: Any) {
    if let episode = podcast?.episodes[tableView.clickedRow] {
      episode.favourite = false
      Library.global.save(episode: episode)
    }
  }
  
  
}
