/*
 * Doughnut Podcast Client
 * Copyright (C) 2017 Chris Dyer
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

class WindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate, DownloadManagerDelegate {
  @IBOutlet var allToggle: NSButton!
  @IBOutlet var newToggle: NSButton!
  @IBOutlet weak var downloadsButton: NSToolbarItem!
  @IBOutlet weak var searchInputView: NSTextField!

  var viewController: ViewController? {
    return window?.contentViewController as? ViewController
  }

  var subscribeViewController: SubscribeViewController {
    get {
      return self.storyboard!.instantiateController(withIdentifier: "SubscribeViewController") as! SubscribeViewController
    }
  }

  override func windowDidLoad() {
    super.windowDidLoad()
    window?.titleVisibility = .hidden

    searchInputView.delegate = self

    downloadsButton.view?.isHidden = true
    Library.global.downloadManager.delegate = self

    NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      if self.keyDown(with: $0) {
        return nil
      } else {
        return $0
      }
    }
  }

  func keyDown(with event: NSEvent) -> Bool {
    if event.characters == " " {
      Player.global.togglePlay()
      return true
    } else {
      return false
    }
  }

  // Subscribed to Search input changes
  func controlTextDidChange(_ obj: Notification) {
    if !searchInputView.stringValue.isEmpty {
      viewController?.search(searchInputView.stringValue.lowercased())
    } else {
      viewController?.search(nil)
    }
  }

  @IBAction func subscribeToPodcast(_ sender: Any) {
    /*let subscribeAlert = NSAlert()
    subscribeAlert.messageText = "Podcast feed URL"
    subscribeAlert.addButton(withTitle: "Ok")
    subscribeAlert.addButton(withTitle: "Cancel")

    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
    input.stringValue = ""

    subscribeAlert.accessoryView = input
    let button = subscribeAlert.runModal()
    if button == .alertFirstButtonReturn {
      Library.global.subscribe(url: input.stringValue)
    }*/

    contentViewController?.presentAsSheet(subscribeViewController)
  }

  @IBAction func reloadAll(_ sender: Any) {
    Library.global.reloadAll()
  }

  @IBAction func newPodcast(_ sender: Any) {
    guard let podcastWindowController = ShowPodcastWindowController.instantiateFromMainStoryboard(),
          let podcastWindow = podcastWindowController.window
    else {
      return
    }
    self.window?.beginSheet(podcastWindow, completionHandler: nil)
  }

  @IBAction func showDownloads(_ button: NSButton) {
    /*guard let downloadsViewController = self.downloadsViewController else { return }

    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = downloadsViewController
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)*/
  }

  @IBAction func toggleAllEpisodes(_ sender: Any) {
    allToggle.state = .on
    newToggle.state = .off

    if let vc = viewController {
      vc.filter(.All)
    }
  }

  @IBAction func toggleNewEpisodes(_ sender: Any) {
    allToggle.state = .off
    newToggle.state = .on

    if let vc = viewController {
      vc.filter(.New)
    }
  }

  func downloadStarted() {
    downloadsButton.view?.isHidden = false
    //self.downloadsViewController?.downloadStarted()
  }

  func downloadFinished() {
    if Library.global.downloadManager.queueCount < 1 {
      downloadsButton.view?.isHidden = true
    }

    //self.downloadsViewController?.downloadFinished()
  }

  func windowDidResignKey(_ notification: Notification) {
    if let player = viewController?.playerViewController.playerView {
      player.needsDisplay = true
    }
  }

  func windowDidBecomeKey(_ notification: Notification) {
    if let player = viewController?.playerViewController.playerView {
      player.needsDisplay = true
    }
  }

  // Control Menu
  @IBAction func playerBackward(_ sender: Any) {
    Player.global.skipBack()
  }

  @IBAction func playerPlay(_ sender: Any) {
    Player.global.play()
  }

  @IBAction func playerForward(_ sender: Any) {
    Player.global.skipAhead()
  }

  @IBAction func volumeUp(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = min(current + 0.1, 1.0)
  }

  @IBAction func volumeDown(_ sender: Any) {
    let current = Player.global.volume
    Player.global.volume = max(current - 0.1, 0.0)
  }
}
