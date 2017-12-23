//
//  ShowPodcastViewController.swift
//  Doughnut
//
//  Created by Chris Dyer on 23/12/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import Cocoa

class ShowPodcastWindowController: NSWindowController {
  override func windowDidLoad() {
    window?.isMovableByWindowBackground = true
    window?.titleVisibility = .hidden
    window?.styleMask.insert([ .resizable ])
    
    window?.standardWindowButton(.closeButton)?.isHidden = true
    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window?.standardWindowButton(.toolbarButton)?.isHidden = true
    window?.standardWindowButton(.zoomButton)?.isHidden = true
  }
}

class ShowPodcastWindow: NSWindow {
  override var canBecomeKey: Bool {
    get {
      return true
    }
  }
}

class ShowPodcastViewController: NSViewController {
  @IBOutlet weak var artworkView: NSImageView!
  @IBOutlet weak var titleLabelView: NSTextField!
  @IBOutlet weak var authorLabelView: NSTextField!
  
  @IBOutlet weak var tabBarView: NSSegmentedControl!
  @IBOutlet weak var tabView: NSTabView!
  
  // Details Tab
  @IBOutlet weak var titleInputView: NSTextField!
  @IBOutlet weak var authorInputView: NSTextField!
  @IBOutlet weak var linkInputView: NSTextField!
  @IBOutlet weak var copyrightInputView: NSTextField!
  
  @IBAction func titleInputEvent(_ sender: NSTextField) {
    titleLabelView.stringValue = sender.stringValue
  }
  
  // Artwork Tab
  @IBOutlet weak var artworkLargeView: NSImageView!
  
  // Description Tab
  @IBOutlet weak var descriptionInputView: NSTextField!
  
  // Options Tab
  
  
  
  override func viewDidLoad() {
    tabBarView.selectedSegment = 0
    tabView.selectTabViewItem(at: 0)
    
    artworkView.wantsLayer = true
    artworkView.layer?.borderWidth = 1.0
    artworkView.layer?.cornerRadius = 3.0
    artworkView.layer?.masksToBounds = true
  }
  
  var podcast: Podcast? {
    didSet {
      artworkView.image = podcast?.image
      titleLabelView.stringValue = podcast?.title ?? ""
      authorLabelView.stringValue = podcast?.author ?? ""
      
      // Details View
      titleInputView.stringValue = podcast?.title ?? ""
      authorInputView.stringValue = podcast?.author ?? ""
      linkInputView.stringValue = podcast?.link ?? ""
      copyrightInputView.stringValue = podcast?.copyright ?? ""
      
      // Artwork View
      if let artwork = podcast?.image {
        artworkLargeView.image = artwork
      }
      
      // Description View
      descriptionInputView.stringValue = podcast?.description ?? ""
    }
  }
  
  @IBAction func switchTab(_ sender: NSSegmentedCell) {
    let clickedSegment = sender.selectedSegment
    tabView.selectTabViewItem(at: clickedSegment)
  }
  
  @IBAction func cancel(_ sender: Any) {
    self.view.window?.close()
  }
  
  @IBAction func savePodcast(_ sender: Any) {
    
    self.view.window?.close()
  }
  
  @IBAction func addArtwork(_ sender: Any) {
  }
  
}
