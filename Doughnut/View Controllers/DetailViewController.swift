//
//  DetailViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa
import WebKit

enum DetailViewType {
  case BlankDetail
  case PodcastDetail
  case EpisodeDetail
}

class DetailViewController: NSViewController, WKNavigationDelegate {
  @IBOutlet weak var detailTitle: NSTextField!
  @IBOutlet weak var secondaryTitle: NSTextField!
  @IBOutlet weak var miniTitle: NSTextField!
  @IBOutlet weak var coverImage: NSImageView!
  
  @IBOutlet weak var webView: WKWebView!
  
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
    
    webView.navigationDelegate = self
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
    
    webView.loadHTMLString(MarkupGenerator.markup(forPodcast: podcast), baseURL: nil)
  }
  
  func showEpisode() {
    guard let episode = episode else {
      showBlank()
      return
    }
    
    detailTitle.stringValue = episode.title
    secondaryTitle.stringValue = podcast?.title ?? ""
    miniTitle.stringValue = episode.link ?? ""
    
    if let artwork = episode.artwork {
      coverImage.image = artwork
    } else {
      coverImage.image = podcast?.image
    }
    
    webView.loadHTMLString(MarkupGenerator.markup(forEpisode: episode), baseURL: nil)
  }
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated {
      if let url = navigationAction.request.url {
        NSWorkspace.shared.open(url)
      }
      
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
}
