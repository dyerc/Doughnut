/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 - 2022 Chris Dyer
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

import AVFoundation
import Cocoa

final class ShowPodcastWindowController: NSWindowController {

  static func instantiateFromMainStoryboard() -> ShowPodcastWindowController? {
    return NSStoryboard.init(name: "PodcastInfo", bundle: nil).instantiateInitialController()
  }

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
    return true
  }
}

class ShowPodcastViewController: NSViewController {
  let defaultPodcastArtwork = NSImage(named: "PodcastPlaceholder")

  @IBOutlet weak var artworkView: NSImageView!
  @IBOutlet weak var titleLabelView: NSTextField!
  @IBOutlet weak var authorLabelView: NSTextField!
  @IBOutlet weak var copyrightLabelView: NSTextField!

  @IBOutlet weak var tabBarView: NSSegmentedControl!
  @IBOutlet weak var tabView: NSTabView!

  @IBOutlet weak var backgroundView: BackgroundView!

  // Details Tab
  @IBOutlet weak var titleInputView: NSTextField!
  @IBOutlet weak var authorInputView: NSTextField!
  @IBOutlet weak var linkInputView: NSTextField!
  @IBOutlet weak var copyrightInputView: NSTextField!

  @IBAction func titleInputEvent(_ sender: NSTextField) {
    titleLabelView.stringValue = sender.stringValue
  }

  @IBAction func authorInputEvent(_ sender: NSTextField) {
    authorLabelView.stringValue = sender.stringValue
  }

  @IBAction func copyrightInputEvent(_ sender: NSTextField) {
    copyrightLabelView.stringValue = sender.stringValue
  }

  // Artwork Tab
  var modifiedImage = false
  @IBOutlet weak var artworkLargeView: NSImageView!

  // Description Tab
  var modifiedDescription = false
  @IBOutlet weak var descriptionInputView: NSTextField!

  // Options Tab
  @IBOutlet weak var reloadInputView: NSPopUpButton!
  @IBOutlet weak var lastParsedLabelView: NSTextField!
  @IBOutlet weak var autoDownloadCheckView: NSButton!
  @IBOutlet weak var storageLabelView: NSTextField!
  @IBOutlet weak var capacityLabelView: NSTextField!

  override func viewDidLoad() {
    tabBarView.selectedSegment = 0
    tabView.selectTabViewItem(at: 0)

    artworkView.wantsLayer = true
    artworkView.layer?.borderWidth = 1.0
    artworkView.layer?.borderColor = NSColor(calibratedWhite: 0.8, alpha: 1.0).cgColor
    artworkView.layer?.cornerRadius = 3.0
    artworkView.layer?.masksToBounds = true

    backgroundView.isMovableByViewBackground = false
  }

  var podcast: Podcast? {
    didSet {
      if let artwork = podcast?.image {
        artworkView.image = artwork
      } else {
        artworkView.image = defaultPodcastArtwork
      }

      titleLabelView.stringValue = podcast?.title ?? ""
      authorLabelView.stringValue = podcast?.author ?? ""
      copyrightLabelView.stringValue = podcast?.copyright ?? ""

      // Details View
      titleInputView.stringValue = podcast?.title ?? ""
      authorInputView.stringValue = podcast?.author ?? ""
      linkInputView.stringValue = podcast?.link ?? ""
      copyrightInputView.stringValue = podcast?.copyright ?? ""

      // Artwork View
      if let artwork = podcast?.image {
        artworkLargeView.image = artwork
      } else {
        artworkLargeView.image = defaultPodcastArtwork
      }

      // Description View
      descriptionInputView.stringValue = podcast?.description ?? ""

      // Options View
      reloadInputView.selectItem(withTag: podcast?.reloadFrequency ?? 0)
      autoDownloadCheckView.state = (podcast?.autoDownload ?? false) ? .on : .off

      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .long
      dateFormatter.timeStyle = .short

      if let lastParsed = podcast?.lastParsed {
        lastParsedLabelView.stringValue = dateFormatter.string(from: lastParsed)
      } else {
        lastParsedLabelView.stringValue = "Never"
      }

      storageLabelView.stringValue = podcast?.storagePath()?.path ?? "Unknown"

      if let podcast = podcast {
        if let capacity = Storage.podcastSize(podcast) {
          capacityLabelView.stringValue = capacity
        }
      } else {
        capacityLabelView.stringValue = "0 GB"
      }
    }
  }

  @IBAction func switchTab(_ sender: NSSegmentedCell) {
    let clickedSegment = sender.selectedSegment
    tabView.selectTabViewItem(at: clickedSegment)
  }

  @IBAction func cancel(_ sender: Any) {
    NSApp.stopModal(withCode: .cancel)
    view.window?.close()
  }

  // Permeate UI input changes to podcat object
  func commitChanges(_ podcast: Podcast) {
    podcast.title = titleInputView.stringValue
    podcast.author = authorInputView.stringValue
    podcast.link = linkInputView.stringValue
    podcast.copyright = copyrightInputView.stringValue

    if modifiedImage {
      if let data = artworkLargeView.image?.tiffRepresentation {
        podcast.storeImage(data)
      }
    }

    if modifiedDescription {
      podcast.description = descriptionInputView.stringValue
    }

    podcast.reloadFrequency = reloadInputView.selectedTag()

    if autoDownloadCheckView.state == .on {
      podcast.autoDownload = true
    } else {
      podcast.autoDownload = false
    }
  }

  @IBAction func savePodcast(_ sender: Any) {
    if let podcast = podcast {
      commitChanges(podcast)

      if Self.validate(forPodcast: podcast) {
        Library.global.update(podcast: podcast) { [weak self] _ in
          DispatchQueue.main.async {
            // TODO: prompt for error on failure
            NSApp.stopModal(withCode: .OK)
            self?.view.window?.close()
          }
        }
      }
    } else {
      // Create new podcast
      let podcast = Podcast(title: titleInputView.stringValue)
      commitChanges(podcast)

      if Self.validate(forPodcast: podcast) {
        Library.global.subscribe(podcast: podcast)
        NSApp.stopModal(withCode: .OK)
        view.window?.close()
      }
    }
  }

  @IBAction func addArtwork(_ sender: Any) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false

    panel.runModal()

    if let url = panel.url {
      if url.pathExtension == "jpg" || url.pathExtension == "png" {
        artworkLargeView.image = NSImage(contentsOfFile: url.path)
      } else {
        let asset = AVAsset(url: url)

        for item in asset.commonMetadata {
          if let key = item.commonKey, let value = item.value {
            if key.rawValue == "artwork" {
              artworkLargeView.image = NSImage(data: value as! Data)
            }
          }
        }
      }

      artworkView.image = artworkLargeView.image
      modifiedImage = true
    }
  }

  static func validate(forPodcast podcast: Podcast) -> Bool {
    if let invalid = podcast.invalid() {
      let alert = NSAlert()
      alert.messageText = "Unable to Save Podcast"
      alert.informativeText = invalid
      alert.runModal()

      return false
    } else {
      return true
    }
  }

}
