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

enum GlobalFilter {
  case All
  case New
}

final class ViewController: NSSplitViewController, LibraryDelegate {

  struct Constants {
    static let playerViewHeight: CGFloat = 38
  }

  enum Events: String {
    case PodcastSelected

    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }

  @IBOutlet var playerViewController: PlayerViewController!

  var globalFilter: GlobalFilter = .All

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

    UserDefaults.standard.addObserver(self, forKeyPath: Preference.Key.showDockBadge.rawValue, options: [], context: nil)
    updateDockIcon()

    splitView.autosaveName = "Main"

    Library.global.delegate = self

    setupPlayerView()
  }

  private func setupPlayerView() {
    view.addSubview(playerViewController.view)
    playerViewController.view.translatesAutoresizingMaskIntoConstraints = false

    let secondColumnController = splitViewItems[1].viewController
    let thirdColumnController = splitViewItems[2].viewController

    view.addConstraints([
      NSLayoutConstraint(
        item: playerViewController.view,
        attribute: .bottom,
        relatedBy: .equal,
        toItem: view,
        attribute: .bottom,
        multiplier: 1,
        constant: 0
      ),
      NSLayoutConstraint(
        item: playerViewController.view,
        attribute: .leading,
        relatedBy: .equal,
        toItem: secondColumnController.view,
        attribute: .leading,
        multiplier: 1,
        constant: 0
      ),
      NSLayoutConstraint(
        item: playerViewController.view,
        attribute: .trailing,
        relatedBy: .equal,
        toItem: thirdColumnController.view,
        attribute: .trailing,
        multiplier: 1,
        constant: 0
      ),
      NSLayoutConstraint(
        item: playerViewController.view,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1,
        constant: Constants.playerViewHeight
      ),
    ])
  }

  deinit {
    UserDefaults.standard.removeObserver(self, forKeyPath: Preference.Key.showDockBadge.rawValue)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    switch keyPath {
    case Preference.Key.showDockBadge.rawValue?:
      updateDockIcon()
    default:
      return
    }
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
    updateDockIcon()
  }

  func librarySubscribedToPodcast(subscribed: Podcast) {
    podcastViewController.reloadPodcasts()
    updateDockIcon()
  }

  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    podcastViewController.reloadPodcasts()

    if episodeViewController.podcast?.id == unsubscribed.id {
      selectPodcast(podcast: nil)
    }

    updateDockIcon()
  }

  func libraryUpdatingPodcast(podcast: Podcast) {
    podcastViewController.reloadPodcasts()
    updateDockIcon()
  }

  func libraryUpdatedPodcast(podcast: Podcast) {
    podcastViewController.reloadPodcasts()

    if episodeViewController.podcast?.id == podcast.id {
      episodeViewController.reloadEpisodes()
    }

    updateDockIcon()
  }

  func libraryUpdatedEpisode(episode: Episode) {
    if episodeViewController.podcast?.id == episode.podcastId {
      episodeViewController.reloadEpisode(episode)
    }

    updateDockIcon()
  }

  // MARK: Actions
  func updateDockIcon() {
    if Preference.bool(for: Preference.Key.showDockBadge) {
      let unplayedCount = Library.global.unplayedCount

      if unplayedCount > 0 {
        NSApplication.shared.dockTile.badgeLabel = String(unplayedCount)
      } else {
        NSApplication.shared.dockTile.badgeLabel = nil
      }
    } else {
      NSApplication.shared.dockTile.badgeLabel = nil
    }
  }

  func filter(_ filter: GlobalFilter) {
    globalFilter = filter

    podcastViewController.filter = globalFilter
    episodeViewController.filter = globalFilter
  }

  func search(_ query: String?) {
    episodeViewController.searchQuery = query
  }
}
