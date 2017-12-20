//
//  EditEpisodeViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 20/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EpisodeWindowFormBackground: NSView {
  override func draw(_ dirtyRect: NSRect) {
    // Fill bottom of window with white bg
    let rect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    NSColor.white.setFill()
    rect.fill()
  }
}

class EditEpisodeViewController: NSViewController {
  @IBOutlet weak var titleTxt: NSTextField!
  @IBOutlet weak var guidTxt: NSTextField!
  @IBOutlet weak var descriptionTxt: NSTextField!
  @IBOutlet weak var publishedDate: NSDatePicker!
  @IBOutlet weak var artworkImg: NSImageView!
  
  @IBOutlet weak var episodeTitleTxt: NSTextField!
  @IBOutlet weak var podcastTitleTxt: NSTextField!
  @IBOutlet weak var podcastAuthorTxt: NSTextField!
  
  var episode: Episode? {
    didSet {
      guard let episode = episode else { return }
      
      titleTxt.stringValue = episode.title
      episodeTitleTxt.stringValue = episode.title
      guidTxt.stringValue = episode.guid
      descriptionTxt.stringValue = episode.description ?? ""
      publishedDate.dateValue = episode.pubDate ?? Date()
      
      if let podcast = episode.podcast {
        podcastTitleTxt.stringValue = podcast.title
        podcastAuthorTxt.stringValue = podcast.author ?? ""
      }
      
      if let artwork = episode.artwork {
        artworkImg.image = artwork
      }
    }
  }
  
  override func viewWillAppear() {
    if let window = self.view.window {
      window.isMovableByWindowBackground = true
    }
  }
  
  @IBAction func cancel(_ sender: Any) {
    self.view.window?.close()
  }
  
  @IBAction func saveEpisode(_ sender: Any) {
    guard let episode = episode else { return }
    
    episode.title = titleTxt.stringValue
    episode.description = descriptionTxt.stringValue
    episode.pubDate = publishedDate.dateValue
    
    Library.global.save(episode: episode)
    self.view.window?.close()
  }
}
