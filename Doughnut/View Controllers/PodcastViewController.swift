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

final class PodcastViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, SortingMenuProviderDelegate {

  enum SortParameter: String {
    case title = "Title"
    case episodes = "Episodes"
    case unplayed = "Unplayed Episodes"
    case favourites = "Favourites"
    case recentEpisodes = "Recently Updated"
  }

  struct Filter: Equatable {
    enum Category: Equatable {
      case all
      case newEpisodes
    }

    var category: Category
    var query: String

    static var all: Self {
      return Self(category: .all, query: "")
    }
  }

  var podcasts = [Podcast]()

  @IBOutlet var tableView: NSTableView!

  @IBOutlet var sortView: NSView!
  @IBOutlet var moreButton: NSButton!
  @IBOutlet var searchField: PodcastSearchField!
  @IBOutlet var filterBarSeparator: NSBox!

  private var sortingMenuProvider: SortingMenuProvider {
    return SortingMenuProvider.Shared.podcasts
  }

  private var tableScrollView: NSScrollView {
    return tableView.enclosingScrollView!
  }

  private var filter: Filter = .all {
    didSet {
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

    searchField.searchFieldDelegate = self
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    let moreButtonCell = moreButton.cell as? NSButtonCell
    moreButtonCell?.highlightsBy = []

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

    tableView.sizeLastColumnToFit()
    updateFilterBarSeparatorVisibility()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    updateFilterBarSeparatorVisibility()
  }

  func reloadPodcasts() {
    reload(forChangedPodcasts: nil)
    tableView.scrollRowToVisible(tableView.selectedRow)
  }

  func reload(forPodcast podcast: Podcast) {
    reload(forChangedPodcasts: [podcast])
  }

  private func reload(forChangedPodcasts changedPodcasts: [Podcast]?) {
    let availableRowIndicesRange = tableView.availableRowIndicesRange

    let podcastIdsBeforeReload = podcasts.map { $0.id }
    let selectedPodcastIdsBeforeReload = tableView.selectedRowIndexes.compactMap {
      return podcasts[$0].id
    }

    podcasts = Library.global.podcasts

    podcasts = podcasts.filter { podcast -> Bool in
      if filter.category == .newEpisodes {
        return podcast.unplayedCount > 0
      } else {
        return true
      }
    }

    if !filter.query.isEmpty {
      let query = filter.query.lowercased().filter { !$0.isWhitespace }
      podcasts = podcasts.filter { podcast in
        return podcast.title
          .lowercased().filter { !$0.isWhitespace }
          .contains(query)
      }
    }

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
        guard let aD = a.latestEpisode?.pubDate else { return true }
        guard let bD = b.latestEpisode?.pubDate else { return false }
        return aD < bD
      }
    }

    if sortDirection == .desc {
      podcasts.reverse()
    }

    let podcastIdsAfterReload = podcasts.map { $0.id }

    let podcastIdToIndexMap = podcasts.enumerated().reduce(into: [Int64: Int]()) { dict, pair in
      let (index, item) = pair
      if let id = item.id {
        dict[id] = index
      }
    }

    if podcastIdsBeforeReload.count != podcastIdsAfterReload.count {
      // if item count being changed, a full reload is needed, which triggers `numberOfRowsInTableView:` call
      tableView.reloadData()
    } else {
      // take the short path to only reload at most items in availableRowIndicesRange
      if let changedPodcasts = changedPodcasts {
        let changedIds = changedPodcasts.map { $0.id }
        let changedIndices = podcastIdToIndexMap.compactMap { pair -> Int? in
          return changedIds.contains(pair.key) ? pair.value : nil
        }
        let indicesToReload = availableRowIndicesRange.filter { index in
          if changedIndices.contains(index) {
            return true
          } else {
            guard index < podcastIdsBeforeReload.count, index < podcastIdsAfterReload.count else {
              return false
            }
            return podcastIdsBeforeReload[index] != podcastIdsAfterReload[index]
          }
        }
        tableView.reloadData(forRowIndexes: IndexSet(indicesToReload))
      } else {
        // otherwise, reload the entire availableRowIndicesRange
        tableView.reloadData(forRowIndexes: IndexSet(availableRowIndicesRange))
      }
    }

    var selectionIndices = podcastIdToIndexMap.compactMap { pair -> Int? in
      return selectedPodcastIdsBeforeReload.contains(pair.key) ? pair.value : nil
    }

    if selectionIndices.isEmpty, !podcastIdsAfterReload.isEmpty {
      selectionIndices = [0]
    }

    tableView.selectRowIndexes(IndexSet(selectionIndices), byExtendingSelection: false)

    // explicitly deselect since `tableViewSelectionDidChange:` won't call after `selectRowIndexes:byExtendingSelection:`
    if selectionIndices.isEmpty {
      viewController.selectPodcast(podcast: nil)
    }

    updateFilterBarSeparatorVisibility()
  }

  private func updateFilterBarSeparatorVisibility() {
    let hidesSeparator = tableView.frame.height <= tableScrollView.contentView.frame.height
    filterBarSeparator.isHidden = hidesSeparator
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
      result.artwork.image = podcast.image
    } else {
      result.artwork.image = NSImage(named: "PodcastPlaceholder")
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
      Library.global.update(podcast: podcast)
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
      Library.global.update(podcast: podcast)
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

  @IBAction func actionMenuClicked(_ sender: Any) {
    let menu = NSMenu()

    menu.addItem(withTitle: "Sort Podcasts", action: nil, keyEquivalent: "")

    for item in sortingMenuProvider.build(forStyle: .actionMenu).items {
      item.indentationLevel = 1
      menu.addItem(item)
    }

    (sender as? NSView)?.popUpContextualMenu(menu)
  }

}

extension PodcastViewController: PodcastSearchFieldDelegate {

  func podcastSearchFieldDidUpdate(withFilter filter: Filter) {
    self.filter = filter
  }

}

extension PodcastViewController: NSMenuDelegate {

  func menuNeedsUpdate(_ menu: NSMenu) { }

}
