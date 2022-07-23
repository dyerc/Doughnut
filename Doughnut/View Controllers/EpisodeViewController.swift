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

final class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, SortingMenuProviderDelegate {

  enum SortParameter: String {
    case mostRecent = "Most Recent"
    case favourites = "Favourites"
  }

  enum Filter {
    case all
    case unplayed
  }

  var podcast: Podcast?
  var episodes = [Episode]()

  private var sortingMenuProvider: SortingMenuProvider {
    return SortingMenuProvider.Shared.episodes
  }

  private var tableScrollView: NSScrollView {
    return tableView.enclosingScrollView!
  }

  var sortBy: SortParameter = .mostRecent {
    didSet {
      Preference.set(sortBy.rawValue, for: Preference.Key.episodeSortParam)
    }
  }

  var sortDirection: SortDirection = .desc {
    didSet {
      Preference.set(sortDirection.rawValue, for: Preference.Key.episodeSortDirection)
    }
  }

  var filter: Filter = .all {
    didSet {
      updateFilteringButtonState()
      reloadEpisodes()
    }
  }

  var searchQuery: String? {
    didSet {
      reloadEpisodes()
    }
  }

  @IBOutlet var tableView: NSTableView!
  @IBOutlet var sortView: NSView!
  @IBOutlet var sortingButton: NSButton!
  @IBOutlet var filteringButton: NSButton!

  var filterEpisodesToolbarItem: NSToolbarItem? {
    return (view.window?.windowController as? WindowController)?.filterEpisodesToolbarItem
  }

  var viewController: ViewController {
    return parent as! ViewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(macOS 11.0, *) {
      tableView.style = .inset
      filteringButton.isHidden = true
    }

    NSLayoutConstraint(
      item: sortView!,
      attribute: .top,
      relatedBy: .equal,
      toItem: view.compatibleSafeAreaLayoutGuide,
      attribute: .top,
      multiplier: 1,
      constant: 0
    ).isActive = true

    if let sortPreference = Preference.string(for: Preference.Key.episodeSortParam), let sortParam = SortParameter(rawValue: sortPreference) {
      sortBy = sortParam
    }

    if Preference.string(for: Preference.Key.episodeSortDirection) == "Ascending" {
      sortDirection = .asc
    } else {
      sortDirection = .desc
    }

    sortingMenuProvider.sortParam = sortBy.rawValue
    sortingMenuProvider.sortDirection = sortDirection
    sortingMenuProvider.delegate = self

    sortingButton.menu = sortingMenuProvider.build(forStyle: .pullDownMenu)

    filteringButton.contentTintColor = .secondaryLabelColor

    tableView.registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    updateFilteringButtonState()

    let scrollViewTopInset: CGFloat
    if #available(macOS 11.0, *) {
      scrollViewTopInset = view.safeAreaInsets.top
    } else {
      scrollViewTopInset = 0
    }

    tableScrollView.automaticallyAdjustsContentInsets = false
    tableScrollView.contentInsets = NSEdgeInsets(
      top: scrollViewTopInset + sortView.bounds.height,
      left: 0,
      bottom: 0,
      right: 0
    )

    tableView.sizeLastColumnToFit()
  }

  private func updateFilteringButtonState() {
    if #available(macOS 11.0, *) {
      filterEpisodesToolbarItem?.image = filter == .all
                               ? NSImage(systemSymbolName: "line.horizontal.3.decrease.circle", accessibilityDescription: nil)
                               : NSImage(systemSymbolName: "line.horizontal.3.decrease.circle.fill", accessibilityDescription: nil)
    }

    filteringButton.image = filter == .all
                          ? NSImage(named: "FilterInactive")
                          : NSImage(named: "FilterActive")
  }

  func reloadEpisodes() {
    reload(forChangedEpisodes: nil)
    tableView.scrollRowToVisible(tableView.selectedRow)
  }

  func reload(forChangedEpisodes changedEpisodes: [Episode]?) {
    let availableRowIndicesRange = tableView.availableRowIndicesRange

    let episodeIdsBeforeReload = episodes.map { $0.id }
    let selectedEpisodeIdsBeforeReload = tableView.selectedRowIndexes.compactMap {
      return episodes[$0].id
    }

    if let podcast = podcast {
      episodes = podcast.episodes

      // Global All | New filter
      episodes = episodes.filter { episode -> Bool in
        if filter == .unplayed {
          return !episode.played
        } else {
          return true
        }
      }

      // Filter based on possible search query
      if let query = searchQuery {
        episodes = episodes.filter({ episode -> Bool in
          let description = episode.description ?? ""
          return episode.title.lowercased().contains(query) || description.lowercased().contains(query)
        })
      }

      episodes.sort(by: { (a, b) -> Bool in
        switch sortBy {
        case .mostRecent:
          guard let aD = a.pubDate else { return false }
          guard let bD = b.pubDate else { return true }

          return aD.compare(bD) == .orderedAscending
        case .favourites:
          return (a.favourite ? 1 : 0) < (b.favourite ? 1 : 0)
        }
      })

      if sortDirection == .desc {
        episodes.reverse()
      }
    } else {
      episodes = []
    }

    // Handle an empty table
    if episodes.isEmpty {
    }

    let episodeIdsAfterReload = episodes.map { $0.id }

    let episodeIdToIndexMap = episodes.enumerated().reduce(into: [Int64: Int]()) { dict, pair in
      let (index, item) = pair
      if let id = item.id {
        dict[id] = index
      }
    }

    if episodeIdsBeforeReload.count != episodeIdsAfterReload.count {
      // if item count being changed, a full reload is needed, which triggers `numberOfRowsInTableView:` call
      tableView.reloadData()
    } else {
      // take the short path to only reload at most items in availableRowIndicesRange
      if let changedEpisodes = changedEpisodes {
        let changedIds = changedEpisodes.map { $0.id }
        let changedIndices = episodeIdToIndexMap.compactMap { pair -> Int? in
          return changedIds.contains(pair.key) ? pair.value : nil
        }
        let indicesToReload = availableRowIndicesRange.filter { index in
          if changedIndices.contains(index) {
            return true
          } else {
            guard index < episodeIdsBeforeReload.count, index < episodeIdsAfterReload.count else {
              return false
            }
            return episodeIdsBeforeReload[index] != episodeIdsAfterReload[index]
          }
        }
        tableView.reloadData(forRowIndexes: IndexSet(indicesToReload))
      } else {
        // otherwise, reload the entire availableRowIndicesRange
        tableView.reloadData(forRowIndexes: IndexSet(availableRowIndicesRange))
      }
    }

    var selectionIndices = episodeIdToIndexMap.compactMap { pair -> Int? in
      return selectedEpisodeIdsBeforeReload.contains(pair.key) ? pair.value : nil
    }

    if !selectedEpisodeIdsBeforeReload.isEmpty, selectionIndices.isEmpty, !episodeIdsAfterReload.isEmpty {
      selectionIndices = [0]
    }

    tableView.selectRowIndexes(IndexSet(selectionIndices), byExtendingSelection: false)

    // explicitly deselect since `tableViewSelectionDidChange:` won't call after `selectRowIndexes:byExtendingSelection:`
    if selectionIndices.isEmpty {
      viewController.selectEpisode(episode: nil)
    }
  }

  func selectPodcast(_ selectedPodcast: Podcast?) {
    let shouldClearSelection = (selectedPodcast?.id != podcast?.id)

    podcast = selectedPodcast
    reloadEpisodes()

    if shouldClearSelection {
      // Clear selection and reset table state
      tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
      tableView.scrollRowToVisible(0)
    }
  }

  @objc func podcastUpdated(_ notification: NSNotification) {
    if podcast?.id == notification.userInfo?["podcastId"] as? Int64 {
      reloadEpisodes()
    }
  }

  func numberOfRows(in tableView: NSTableView) -> Int {
    return episodes.count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! EpisodeCellView
    result.episode = episodes[row]

    return result
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let episodeToSelect: Episode?
    if tableView.selectedRow != -1, tableView.selectedRow < episodes.count {
      episodeToSelect = episodes[tableView.selectedRow]
    } else {
      episodeToSelect = nil
    }
    viewController.selectEpisode(episode: episodeToSelect)
  }

  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
    return NSDragOperation.every
  }

  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
    guard let podcast = podcast else { return false }

    let pasteboard = info.draggingPasteboard
    guard let items = pasteboard.pasteboardItems else { return true }

    var moveToLibrary = true
    let alert = NSAlert()
    alert.addButton(withTitle: "Copy to Library")
    alert.addButton(withTitle: "Link to Library")
    alert.addButton(withTitle: "Cancel")
    alert.messageText = "Copy these files into your Doughnut library?"

    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      moveToLibrary = true
    } else if result == .alertSecondButtonReturn {
      moveToLibrary = false
    } else {
      return false
    }

    for item in items {
      guard let stringURL = item.string(forType: NSPasteboard.PasteboardType(kUTTypeFileURL as String)) else { continue }
      guard let sourceURL = URL(string: stringURL) else { continue }

      Episode.fromFile(podcast: podcast, url: sourceURL, copyToLibrary: moveToLibrary, completion: { episode in
        podcast.episodes.append(episode)
        Library.global.update(podcast: podcast)
      })
    }

    return true
  }

  @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let menuType = menuItem.menuType
    let allowHidingMenuItem = menuType != .main

    let episodes = activeEpisodesForAction()

    switch menuItem.action {
    case #selector(playNow(_:)):
      return episodes.count == 1
    case #selector(getInfo(_:)):
      fallthrough
    case #selector(showEpisode(_:)):
      return episodes.count == 1
    case #selector(togglePlayed(_:)):
      let playedCount = episodes.filter({ $0.played }).count
      let allPlayed = playedCount == episodes.count
      let allUnplayed = playedCount == 0

      menuItem.title = (!allPlayed || episodes.isEmpty) ? "Mark as Played" : "Mark as Unplayed"
      menuItem.state = (!allPlayed && !allUnplayed) ? .mixed : .off

      return !episodes.isEmpty
    case #selector(toggleFavourite(_:)):
      let markedAsFavouriteCount = episodes.filter({ $0.favourite }).count
      let allMarkedAsFavourite = markedAsFavouriteCount == episodes.count
      let allMarkedAsUnFavourite = markedAsFavouriteCount == 0

      menuItem.title = (!allMarkedAsFavourite || episodes.isEmpty) ? "Mark as Favourite" : "Unmark Favourite"
      menuItem.state = (!allMarkedAsFavourite && !allMarkedAsUnFavourite) ? .mixed : .off

      return !episodes.isEmpty
    case #selector(downloadEpisode(_:)):
      menuItem.isHidden = allowHidingMenuItem && episodes.count != 1
      if episodes.count == 1 {
        let episode = episodes.first!
        return episode.enclosureUrl != nil && !episode.downloaded
      } else {
        return false
      }
    case #selector(moveToTrash(_:)):
      menuItem.isHidden = allowHidingMenuItem && episodes.count != 1
      return episodes.count == 1 && episodes.first!.downloaded
    case #selector(showInFinder(_:)):
      menuItem.isHidden = allowHidingMenuItem && episodes.count != 1
      return episodes.count == 1 && episodes.first!.downloaded
    case #selector(delete(_:)):
      fallthrough
    case #selector(deleteEpisode(_:)):
      menuItem.isHidden = allowHidingMenuItem && episodes.count != 1
      return episodes.count == 1
    default:
      assert(false, "Unhandled menu item in \(#function)")
      return false
    }
  }

  private func activeEpisodesForAction() -> [Episode] {
    return tableView.activeRowIndices.compactMap { rowIndex in
      return rowIndex < episodes.count ? episodes[rowIndex] : nil
    }
  }

  func sorted(by: String?, direction: SortDirection) {
    if let sortParam = SortParameter(rawValue: by ?? "") {
      sortBy = sortParam
    }

    sortDirection = direction

    // Rebuild the pulldown menu after sorting to ensure its title being updated
    // We should have an another mechanism to trigger menu updates. For now it's
    // fine to keep it simple.
    sortingButton.menu = sortingMenuProvider.build(forStyle: .pullDownMenu)

    reloadEpisodes()
  }

  func toggleFilter() {
    filter = (filter == .unplayed) ? .all : .unplayed
  }

  // MARK: - Actions

  @IBAction func episodeDoubleClicked(_ sender: Any) {
    guard tableView.clickedRow != -1, tableView.clickedRow < episodes.count else {
      return
    }

    let episode = episodes[tableView.clickedRow]
    Player.global.play(episode: episode)
  }

  @IBAction func playNow(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)
    guard let episode = episodes.first else { return }

    Player.global.play(episode: episode)
  }

  @IBAction func togglePlayed(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    let playedCount = episodes.filter({ $0.played }).count
    let allPlayed = playedCount == episodes.count

    let shouldMarkPlayed = !allPlayed

    Library.global.batchUpdateEpisodes(played: shouldMarkPlayed, episodes: episodes)
  }

  @IBAction func toggleFavourite(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    let favouriteCount = episodes.filter({ $0.favourite }).count
    let allMarkedAsFavourite = favouriteCount == episodes.count

    let shouldMarkAsFavourite = !allMarkedAsFavourite

    Library.global.batchUpdateEpisodes(favourite: shouldMarkAsFavourite, episodes: episodes)
  }

  @IBAction func downloadEpisode(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)
    guard let episode = episodes.first else { return }

    // Library.global.downloadManager.queueDownload(episode: episode)
    episode.download()
  }

  @IBAction func moveToTrash(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)
    guard let episode = episodes.first else { return }

    episode.downloaded = false
    episode.fileName = nil
    Library.global.save(episode: episode)
  }

  @IBAction func delete(_ sender: Any) {
    deleteEpisode(sender)
  }

  @IBAction func deleteEpisode(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)

    guard let episode = episodes.first, let podcast = episode.podcast else {
      return
    }

    var moveToTrash = false
    if episode.downloaded {
      let alert = NSAlert()
      alert.addButton(withTitle: "Leave File(s)")
      alert.addButton(withTitle: "Move to Trash")
      alert.messageText = "Move File(s) to Trash"
      alert.informativeText = "Would you like to move this episode's downloaded file to the trash"

      let result = alert.runModal()
      if result == .alertFirstButtonReturn {
        moveToTrash = false
      } else {
        moveToTrash = true
      }
    }

    if moveToTrash {
      podcast.deleteEpisodeAndTrash(episode: episode)
    } else {
      podcast.deleteEpisode(episode: episode)
    }
  }

  @IBAction func getInfo(_ sender: Any) {
    showEpisode(sender)
  }

  @IBAction func showEpisode(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)
    guard let episode = episodes.first else { return }

    guard let episodeWindowController = ShowEpisodeWindowController.instantiateFromMainStoryboard(),
          let episodeViewController = episodeWindowController.contentViewController as? ShowEpisodeViewController,
          let episodeWindow = episodeWindowController.window
    else {
      return
    }
    episodeViewController.episode = episode
    NSApp.runModal(for: episodeWindow)
  }

  @IBAction func showInFinder(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    assert(episodes.count == 1)

    guard let episode = episodes.first, let podcast = episode.podcast else {
      return
    }

    NSWorkspace.shared.selectFile(episode.url()?.path, inFileViewerRootedAtPath: podcast.path)
  }

}

extension EpisodeViewController: NSMenuDelegate {

  func menuNeedsUpdate(_ menu: NSMenu) { }

}
