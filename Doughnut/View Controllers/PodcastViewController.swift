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

final class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, SortingMenuProviderDelegate {

  enum SortParameter: String {
    case title = "Title"
    case episodes = "Episodes"
    case unplayed = "Unplayed"
    case favourites = "Favourited"
    case recentEpisodes = "Recent Episode"
  }

  enum Filter {
    case all
    case newEpisodes
  }

  var podcasts = [Podcast]()

  @IBOutlet var tableView: NSTableView!
  @IBOutlet var sortView: NSView!
  @IBOutlet var filteringButton: NSButton!

  private var sortingMenuProvider: SortingMenuProvider {
    return SortingMenuProvider.Shared.podcasts
  }

  private var tableScrollView: NSScrollView {
    return tableView.enclosingScrollView!
  }

  var filter: Filter = .all {
    didSet {
      updateFilteringButtonState()
      reloadPodcasts()
    }
  }

  var sortBy: SortParameter = .title {
    didSet {
      Preference.set(sortBy.rawValue, for: Preference.Key.podcastSortParam)
    }
  }

  var sortDirection: SortDirection = .desc {
    didSet {
      Preference.set(sortDirection.rawValue, for: Preference.Key.podcastSortDirection)
    }
  }

  var viewController: ViewController {
    get {
      return parent as! ViewController
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(macOS 11.0, *) {
      tableView.style = .sourceList
    }

    if let sortPreference = Preference.string(for: Preference.Key.podcastSortParam), let sortParam = SortParameter(rawValue: sortPreference) {
      sortBy = sortParam
    }

    if Preference.string(for: Preference.Key.podcastSortDirection) == "Ascending" {
      sortDirection = .asc
    } else {
      sortDirection = .desc
    }

    sortingMenuProvider.sortParam = sortBy.rawValue
    sortingMenuProvider.sortDirection = sortDirection
    sortingMenuProvider.delegate = self

    reloadPodcasts()
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    updateFilteringButtonState()

    tableScrollView.automaticallyAdjustsContentInsets = false

    let scrollViewTopInset: CGFloat
    if #available(macOS 11.0, *) {
      scrollViewTopInset = view.safeAreaInsets.top
    } else {
      scrollViewTopInset = 0
    }

    tableScrollView.contentInsets = NSEdgeInsets(
      top: scrollViewTopInset,
      left: 0,
      bottom: sortView.bounds.height,
      right: 0
    )
  }

  private func updateFilteringButtonState() {
    filteringButton.contentTintColor = filter == .all
                                     ? .secondaryLabelColor
                                     : .controlAccentColor
    filteringButton.image = filter == .all
                          ? NSImage(named: "FilterInactive")
                          : NSImage(named: "FilterActive")
  }

  func reloadPodcasts() {
    podcasts = Library.global.podcasts

    podcasts = podcasts.filter({ podcast -> Bool in
      if filter == .newEpisodes {
        return podcast.unplayedCount > 0
      } else {
        return true
      }
    })

    // Sort into ascending order
    podcasts.sort { (a, b) -> Bool in
      switch sortBy {
      case .title:
        return a.title < b.title
      case .episodes:
        return a.episodes.count < b.episodes.count
      case .favourites:
        return a.favouriteCount < b.favouriteCount
      case .unplayed:
        return a.unplayedCount < b.unplayedCount
      case .recentEpisodes:
        guard let aD = a.latestEpisode?.pubDate else { return false }
        guard let bD = b.latestEpisode?.pubDate else { return true }

        return aD < bD
      }
    }

    if sortDirection == .desc {
      podcasts.reverse()
    }

    let selectedRow = tableView.selectedRow
    tableView.reloadData()
    tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
  }

  func reload(forPodcast podcast: Podcast) {
    if let index = podcasts.firstIndex(where: { $0.id == podcast.id }) {
      tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    return podcasts.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let podcast = podcasts[row]
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! PodcastCellView

    result.title.stringValue = podcast.title
    result.author.stringValue = podcast.author ?? ""

    if podcast.image != nil && podcast.image!.isValid {
      result.imageView?.image = podcast.image
    } else {
      result.imageView?.image = NSImage(named: "PodcastPlaceholder")
    }

    result.episodeCount.stringValue = "\(podcast.episodes.count) episodes"
    result.podcastUnplayedCount.value = podcast.unplayedCount
    result.loading = podcast.loading

    return result
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    //NotificationCenter.default.post(name: ViewController.Events.PodcastSelected.notification, object: nil, userInfo: ["podcast": podcasts[row]])
    let podcastToSelect: Podcast?
    if tableView.selectedRow != -1, tableView.selectedRow < podcasts.count {
      podcastToSelect = podcasts[tableView.selectedRow]
    } else {
      podcastToSelect = nil
    }
    viewController.selectPodcast(podcast: podcastToSelect)
  }

  private func activePodcastsForAction() -> [Podcast] {
    return tableView.activeRowIndices.compactMap { rowIndex in
      return rowIndex < podcasts.count ? podcasts[rowIndex] : nil
    }
  }

  func sorted(by: String?, direction: SortDirection) {
    if let sortParam = SortParameter(rawValue: by ?? "") {
      sortBy = sortParam
    }

    sortDirection = direction

    reloadPodcasts()
  }

  // MARK: - Actions

  @IBAction func toggleFilterPodcasts(_ sender: Any) {
    filter = (filter == .newEpisodes) ? .all : .newEpisodes
  }

  @IBAction func reloadPodcast(_ sender: Any) {
    let podcasts = activePodcastsForAction()
    assert(podcasts.count == 1)
    guard let podcast = podcasts.first else { return }

    Library.global.reload(podcast: podcast)
  }

  @IBAction func getInfo(_ sender: Any) {
    podcastInfo(sender)
  }

  @IBAction func podcastInfo(_ sender: Any) {
    let podcasts = activePodcastsForAction()
    assert(podcasts.count == 1)
    guard let podcast = podcasts.first else { return }

    guard let podcastWindowController = ShowPodcastWindowController.instantiateFromMainStoryboard(),
          let podcastViewController = podcastWindowController.contentViewController as? ShowPodcastViewController,
          let podcastWindow = podcastWindowController.window
    else {
      return
    }
    podcastViewController.podcast = podcast
    NSApp.runModal(for: podcastWindow)
  }

  @IBAction func markAllAsPlayed(_ sender: Any) {
    let podcasts = activePodcastsForAction()

    for podcast in podcasts {
      for episode in podcast.episodes {
        episode.played = true
      }

      // Manually trigger a view reload to make update seem instant
      viewController.libraryUpdatedPodcast(podcast: podcast)

      // Commit changes to library
      Library.global.save(podcast: podcast)
    }
  }

  @IBAction func markAllAsUnplayed(_ sender: Any) {
    let podcasts = activePodcastsForAction()

    for podcast in podcasts {
      for episode in podcast.episodes {
        episode.played = false
      }

      // Manually trigger a view reload to make update seem instant
      viewController.libraryUpdatedPodcast(podcast: podcast)

      // Commit changes to library
      Library.global.save(podcast: podcast)
    }
  }

  @IBAction func copyPodcastURL(_ sender: Any) {
    let podcasts = activePodcastsForAction()
    assert(podcasts.count == 1)

    guard let podcast = podcasts.first, let feed = podcast.feed else {
      return
    }

    NSPasteboard.general.declareTypes([.string], owner: nil)
    NSPasteboard.general.setString(feed, forType: .string)
  }

  @IBAction func delete(_ sender: Any) {
    unsubscribe(sender)
  }

  @IBAction func unsubscribe(_ sender: Any) {
    let podcasts = activePodcastsForAction()
    assert(podcasts.count == 1)
    guard let podcast = podcasts.first else { return }

    let alert = NSAlert()
    alert.addButton(withTitle: "Leave Files")
    alert.addButton(withTitle: "Move to Trash")
    alert.addButton(withTitle: "Cancel")
    alert.messageText = "Move Files to Trash"
    alert.informativeText = "Would you like to move any downloaded episodes to the trash?"

    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      Library.global.unsubscribe(podcast: podcast, removeFiles: false)
    } else if result == .alertSecondButtonReturn {
      Library.global.unsubscribe(podcast: podcast, removeFiles: true)
    }
  }

  @IBAction func refreshAll(_ sender: Any) {
    Library.global.reloadAll()
  }

  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let podcasts = activePodcastsForAction()

    switch menuItem.action {
    case #selector(toggleFilterPodcasts(_:)):
      menuItem.state = filter == .newEpisodes ? .on : .off
      return true
    case #selector(reloadPodcast(_:)):
      return podcasts.count == 1
    case #selector(getInfo(_:)):
      fallthrough
    case #selector(podcastInfo(_:)):
      return podcasts.count == 1
    case #selector(markAllAsPlayed(_:)):
      return !podcasts.isEmpty
    case #selector(markAllAsUnplayed(_:)):
      return !podcasts.isEmpty
    case #selector(copyPodcastURL(_:)):
      return podcasts.count == 1
    case #selector(delete(_:)):
      fallthrough
    case #selector(unsubscribe(_:)):
      return podcasts.count == 1
    case #selector(refreshAll(_:)):
      return true
    default:
      assert(false, "Unhandled menu item in \(#function)")
      return false
    }
  }

}

extension PodcastViewController: NSMenuDelegate {

  func menuNeedsUpdate(_ menu: NSMenu) {
    for menuItem in menu.items {
      switch menuItem.identifier?.rawValue {
      case "podcastViewSortBy":
        menuItem.submenu = sortingMenuProvider.buildMenu()
      default:
        break
      }
    }
  }

}
