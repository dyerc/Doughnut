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

final class ViewController: NSSplitViewController, LibraryDelegate {

  static let minimumWidthToShowWindowTitle: CGFloat = 930

  enum Events: String {
    case PodcastSelected

    var notification: Notification.Name {
      return Notification.Name(rawValue: self.rawValue)
    }
  }

  var podcastViewController: PodcastViewController {
    return splitViewItems[0].viewController as! PodcastViewController
  }

  var episodeViewController: EpisodeViewController {
    return splitViewItems[1].viewController as! EpisodeViewController
  }

  var detailViewController: DetailViewController {
    return splitViewItems[2].viewController as! DetailViewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    UserDefaults.standard.addObserver(self, forKeyPath: Preference.Key.showDockBadge.rawValue, options: [], context: nil)

    splitView.autosaveName = "Main"

    Library.global.delegate = self
  }

  override func viewWillAppear() {
    super.viewWillAppear()

    updateWindowTitleAndDockIcon()
  }

  deinit {
    UserDefaults.standard.removeObserver(self, forKeyPath: Preference.Key.showDockBadge.rawValue)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    switch keyPath {
    case Preference.Key.showDockBadge.rawValue?:
      updateWindowTitleAndDockIcon()
    default:
      return
    }
  }

  func selectPodcast(podcast: Podcast?) {
    episodeViewController.selectPodcast(podcast)
    detailViewController.podcast = podcast
    updateWindowTitle()
  }

  func selectEpisode(episode: Episode?) {
    detailViewController.episode = episode
  }

  // MARK: Library Delegate
  func libraryReloaded() {
    podcastViewController.reloadPodcasts()
    updateWindowTitleAndDockIcon()
  }

  func librarySubscribedToPodcast(subscribed: Podcast) {
    podcastViewController.reloadPodcasts()
    updateWindowTitleAndDockIcon()
  }

  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    podcastViewController.reloadPodcasts()

    if episodeViewController.podcast?.id == unsubscribed.id {
      selectPodcast(podcast: nil)
    }

    updateWindowTitleAndDockIcon()
  }

  func libraryUpdatingPodcasts(podcasts: [Podcast]) {
    podcastViewController.reload(forChangedPodcasts: podcasts)
    updateWindowTitleAndDockIcon()
  }

  func libraryUpdatedPodcasts(podcasts: [Podcast]) {
    podcastViewController.reload(forChangedPodcasts: podcasts)

    if podcasts.contains(where: { episodeViewController.podcast?.id == $0.id }) {
      episodeViewController.reloadEpisodes()
    }

    updateWindowTitleAndDockIcon()
  }

  func libraryUpdatedEpisodes(episodes: [Episode]) {
    let currentEpisodes = episodes.filter {
      episodeViewController.podcast?.id == $0.podcastId
    }

    episodeViewController.reload(forChangedEpisodes: currentEpisodes)

    var podcasts = [Podcast]()

    for episode in episodes {
      if let podcast = episode.podcast, !podcasts.contains(where: { $0 === podcast }) {
        podcasts.append(podcast)
      }
    }

    podcastViewController.reload(forChangedPodcasts: podcasts)

    updateWindowTitleAndDockIcon()
  }

  // MARK: Actions

  @IBAction func toggleFilterEpisodes(_ sender: Any) {
    // sender
    episodeViewController.toggleFilter()
  }

  func updateWindowTitleVisibility() {
    if #available(macOS 11.0, *) {
      let primaryColumnsWidth = episodeViewController.view.bounds.width + detailViewController.view.bounds.width
      view.window?.titleVisibility = primaryColumnsWidth >= Self.minimumWidthToShowWindowTitle
                                   ? .visible : .hidden
    }
  }

  private func updateWindowTitle() {
    if #available(macOS 11.0, *) {
      if let podcast = detailViewController.podcast {
        view.window?.title = podcast.title
        view.window?.subtitle = "\(podcast.unplayedCount) Unplayed"
      } else {
        view.window?.title = "Doughnut"
        view.window?.subtitle = ""
      }
    }
  }

  private func updateWindowTitleAndDockIcon() {
    updateWindowTitle()
    updateDockIcon()
  }

  private func updateDockIcon() {
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

  func search(_ query: String?) {
    episodeViewController.searchQuery = query
  }

}

extension ViewController {

  override func splitViewDidResizeSubviews(_ notification: Notification) {
    updateWindowTitleVisibility()
  }

}
