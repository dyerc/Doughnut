//
//  EditPodcastViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 30/11/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class EditPodcastViewController: NSViewController {
  @IBOutlet weak var titleTxt: NSTextField!
  @IBOutlet weak var authorTxt: NSTextField!
  @IBOutlet weak var descriptionTxt: NSTextField!
  
  var podcast: Podcast?
  
  override func viewDidLoad() {
    
  }
  
  func validate() -> Bool {
    var error: String? = nil
    
    if (titleTxt.stringValue.characters.count < 1) {
      error = "Podcast must have a title"
    }
    
    if let error = error {
      let alert = NSAlert()
      alert.messageText = error
      alert.runModal()
      
      return false
    } else {
      return true
    }
  }
  
  @IBAction func savePodcast(_ sender: Any) {
    guard validate() else { return }
    
    if let podcast = podcast {
      Library.global.save(podcast: podcast)
      dismiss(self)
    } else {
      // Create new podcast
      let podcast = Podcast(title: titleTxt.stringValue)
      podcast.author = authorTxt.stringValue
      podcast.description = descriptionTxt.stringValue
      
      Library.global.subscribe(podcast: podcast)
      dismiss(self)
    }
  }
}
