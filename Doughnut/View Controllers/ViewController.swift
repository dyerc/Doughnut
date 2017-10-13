//
//  ViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 22/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class ViewController: NSSplitViewController, LibraryDelegate {
  enum Events:String {
    case PodcastSelected = "PodcastSelected"
    
    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }
  
  var podcastViewController: PodcastViewController {
    get {
      return splitViewItems[0].viewController as! PodcastViewController
    }
  }
  
  var episodeViewController: EpisodeViewController {
    get {
      return splitViewItems[1].viewController as! EpisodeViewController
    }
  }
  
  var detailViewController: DetailViewController {
    get {
      return splitViewItems[2].viewController as! DetailViewController
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    Library.global.delegate = self
  }
  
  func selectPodcast(podcast: Podcast?) {
    episodeViewController.selectPodcast(podcast)
    detailViewController.podcast = podcast
  }
  
  func selectEpisode(episode: Episode?) {
    detailViewController.episode = episode
  }
  
  // MARK: Library Delegate
  func libraryReloaded() {
    podcastViewController.reloadPodcasts()
  }
  
  func librarySubscribedToPodcast(subscribed: Podcast) {
    podcastViewController.reloadPodcasts()
  }
  
  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    podcastViewController.reloadPodcasts()
    
    if episodeViewController.podcast?.id == unsubscribed.id {
      selectPodcast(podcast: nil)
    }
  }
  
  func libraryUpdatedPodcast(podcast: Podcast) {
    podcastViewController.reloadPodcasts()
    
    if episodeViewController.podcast?.id == podcast.id {
      episodeViewController.reloadEpisodes()
    }
  }
  
  func libraryUpdatedEpisode(episode: Episode) {
    
  }
}

