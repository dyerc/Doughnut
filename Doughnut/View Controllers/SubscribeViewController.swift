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

import Cocoa

class SubscribeViewController: NSViewController, NSTextFieldDelegate {
  let reducedHeight: CGFloat = 120.0
  var initialHeight: CGFloat = 0

  @IBOutlet weak var urlTxt: NSTextField!
  @IBOutlet weak var loadingIndicator: NSProgressIndicator!

  @IBOutlet weak var imageView: NSImageView!
  @IBOutlet weak var feedTitleTxt: NSTextField!
  @IBOutlet weak var feedDescriptionTxt: NSTextField!

  @IBOutlet weak var loadBtn: NSButton!
  @IBOutlet weak var cancelBtn: NSButton!
  @IBOutlet weak var subscribeBtn: NSButton!

  var detectedPodcast: Podcast?

  override func viewDidLoad() {
    initialHeight = view.frame.height

    preferredContentSize = CGSize(width: view.frame.size.width, height: reducedHeight)

    loadingIndicator.stopAnimation(self)

    imageView.isHidden = true
    feedTitleTxt.isHidden = true
    feedDescriptionTxt.isHidden = true
    subscribeBtn.isHidden = true

    // Check pasteboard for feed
    if let pastedUrl = NSPasteboard.general.string(forType: .string) {
      if pastedUrl.starts(with: "http") {
        urlTxt.stringValue = pastedUrl
        loadFeed(self)
      }
    }
  }

  @IBAction func loadFeed(_ sender: Any) {
    let loading = Podcast.detect(url: urlTxt.stringValue) { podcast in
      self.loadBtn.isEnabled = true
      self.loadingIndicator.stopAnimation(self)

      if let podcast = podcast {
        self.subscribeBtn.isEnabled = true
        self.imageView.image = podcast.image
        self.feedTitleTxt.stringValue = podcast.title
        self.feedDescriptionTxt.stringValue = podcast.description ?? ""

        self.detectedPodcast = podcast
        self.expand()
      } else {
        let alert = NSAlert()
        alert.messageText = "Unable to Detect Feed URL"
        alert.runModal()
      }
    }

    if loading {
      loadBtn.isEnabled = false
      loadingIndicator.startAnimation(self)
    }
  }

  @IBAction func subscribe(_ sender: Any) {
    guard let detectedPodcast = detectedPodcast else { return }
    Library.global.subscribe(podcast: detectedPodcast)

    dismiss(self)
  }

  func expand() {
    cancelBtn.isHidden = true

    imageView.isHidden = false
    feedTitleTxt.isHidden = false
    feedDescriptionTxt.isHidden = false
    subscribeBtn.isHidden = false

    preferredContentSize = CGSize(width: view.frame.size.width, height: initialHeight)
  }

  func controlTextDidChange(_ obj: Notification) {
    if urlTxt.stringValue.starts(with: "http") && urlTxt.stringValue.contains(".") {
      loadBtn.isEnabled = true
    } else {
      loadBtn.isEnabled = false
    }
  }
}
