//
//  DetailViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

enum DetailViewType {
  case BlankDetail
  case PodcastDetail
  case EpisodeDetail
}

class DetailViewController: NSViewController {
  @IBOutlet weak var detailTitle: NSTextField!
  @IBOutlet weak var secondaryTitle: NSTextField!
  @IBOutlet weak var miniTitle: NSTextField!
  @IBOutlet weak var coverImage: NSImageView!
  
  var detailType: DetailViewType = .BlankDetail {
    didSet {
      switch detailType {
      case .PodcastDetail:
        showPodcast()
        
      case .EpisodeDetail:
        showEpisode()
        
      default:
        showBlank()
      }
    }
  }
  
  var episode: Episode? {
    didSet {
      if episode != nil {
        detailType = .EpisodeDetail
      } else if podcast != nil {
        detailType = .PodcastDetail
      } else {
        detailType = .BlankDetail
      }
    }
  }
  
  var podcast: Podcast? {
    didSet {
      if podcast != nil {
        if podcast?.id != oldValue?.id {
          detailType = .PodcastDetail
        }
      } else {
        detailType = .BlankDetail
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.wantsLayer = true
    view.layer?.backgroundColor = CGColor.white
  }
  
  func showBlank() {
    detailTitle.stringValue = ""
    secondaryTitle.stringValue = ""
    miniTitle.stringValue = ""
  }
  
  func showPodcast() {
    guard let podcast = podcast else {
      showBlank()
      return
    }
    
    detailTitle.stringValue = podcast.title
    secondaryTitle.stringValue = podcast.author ?? ""
    miniTitle.stringValue = podcast.link ?? ""
    coverImage.image = podcast.image
  }
  
  func showEpisode() {
    guard let episode = episode else {
      showBlank()
      return
    }
    
    detailTitle.stringValue = episode.title
    secondaryTitle.stringValue = podcast?.title ?? ""
    miniTitle.stringValue = episode.link ?? ""
    coverImage.image = podcast?.image
  }
}
