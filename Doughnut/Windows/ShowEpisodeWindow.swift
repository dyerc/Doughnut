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

final class ShowEpisodeWindowController: NSWindowController {

  static func instantiateFromMainStoryboard() -> ShowEpisodeWindowController? {
    return NSStoryboard.init(name: "EpisodeInfo", bundle: nil).instantiateInitialController()
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

class ShowEpisodeWindow: NSWindow {
  override var canBecomeKey: Bool {
    return true
  }
}

class ShowEpisodeViewController: NSViewController {
  let defaultPodcastArtwork = NSImage(named: "PodcastPlaceholder")

  @IBOutlet weak var artworkView: NSImageView!
  @IBOutlet weak var titleLabelView: NSTextField!
  @IBOutlet weak var podcastLabelView: NSTextField!
  @IBOutlet weak var authorLabelView: NSTextField!

  @IBOutlet weak var backgroundView: BackgroundView!

  @IBOutlet weak var titleInputView: NSTextField!
  @IBOutlet weak var guidInputView: NSTextField!
  @IBOutlet weak var descriptionInputView: NSTextField!
  @IBOutlet weak var publishedDateInputView: NSDatePicker!

  @IBAction func titleInputEvent(_ sender: NSTextField) {
    titleLabelView.stringValue = sender.stringValue
  }

  override func viewDidLoad() {
    artworkView.wantsLayer = true
    artworkView.layer?.borderWidth = 1.0
    artworkView.layer?.borderColor = NSColor(calibratedWhite: 0.8, alpha: 1.0).cgColor
    artworkView.layer?.cornerRadius = 3.0
    artworkView.layer?.masksToBounds = true

    backgroundView.isMovableByViewBackground = false
  }

  var episode: Episode? {
    didSet {
      guard let episode = episode else { return }

      titleLabelView.stringValue = episode.title
      titleInputView.stringValue = episode.title
      guidInputView.stringValue = episode.guid
      descriptionInputView.stringValue = episode.description ?? ""
      publishedDateInputView.dateValue = episode.pubDate ?? Date()

      if let podcast = episode.podcast {
        podcastLabelView.stringValue = podcast.title
        authorLabelView.stringValue = podcast.author ?? ""

        if let artwork = podcast.image {
          artworkView.image = artwork
        }
      }

      if let artwork = episode.artwork {
        artworkView.image = artwork
      }
    }
  }

  @IBAction func cancel(_ sender: Any) {
    NSApp.stopModal(withCode: .cancel)
    view.window?.close()
  }

  // Permeate UI input changes to podcat object
  func commitChanges(_ episode: Episode) {
    episode.title = titleInputView.stringValue
    episode.pubDate = publishedDateInputView.dateValue
    episode.description = descriptionInputView.stringValue
  }

  @IBAction func saveEpisode(_ sender: Any) {
    if let episode = episode {
      commitChanges(episode)

      if validate() {
        Library.global.save(episode: episode)
        NSApp.stopModal(withCode: .OK)
        view.window?.close()
      }
    }
  }

  func validate() -> Bool {
    guard let episode = episode else { return false }

    if let invalid = episode.invalid() {
      let alert = NSAlert()
      alert.messageText = "Unable to Save Episode"
      alert.informativeText = invalid
      alert.runModal()

      return false
    } else {
      return true
    }
  }
}
