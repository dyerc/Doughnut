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

enum EpisodeSortParameter: String {
  case EpisodeMostRecent = "Most Recent"
  case EpisodeFavourites = "Favourites"
}

class EpisodeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate, SortingViewDelegate {
  var podcast: Podcast?
  var episodes = [Episode]()

  var sortBy: EpisodeSortParameter = .EpisodeMostRecent {
    didSet {
      Preference.set(sortBy.rawValue, for: Preference.Key.episodeSortParam)
    }
  }

  var sortDirection: SortDirection = .Desc {
    didSet {
      Preference.set(sortDirection.rawValue, for: Preference.Key.episodeSortDirection)
    }
  }

  var filter: GlobalFilter = .All {
    didSet {
      reloadEpisodes()
    }
  }

  var searchQuery: String? {
    didSet {
      reloadEpisodes()
    }
  }

  @IBOutlet var tableView: NSTableView!
  @IBOutlet var sortView: SortingView!

  var viewController: ViewController {
    get {
      return parent as! ViewController
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    sortView.menuItemTitles = [
      EpisodeSortParameter.EpisodeFavourites.rawValue,
      EpisodeSortParameter.EpisodeMostRecent.rawValue,
    ]

    if let sortPreference = Preference.string(for: Preference.Key.episodeSortParam), let sortParam = EpisodeSortParameter(rawValue: sortPreference) {
      sortBy = sortParam
    }

    if Preference.string(for: Preference.Key.episodeSortDirection) == "Ascending" {
      sortDirection = .Asc
    } else {
      sortDirection = .Desc
    }

    sortView.sortParam = sortBy.rawValue
    sortView.sortDirection = sortDirection
    sortView.delegate = self

    let scrollView = tableView.enclosingScrollView!
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.contentInsets = NSEdgeInsets(
      top: 0,
      left: 0,
      bottom: ViewController.Constants.playerViewHeight,
      right: 0
    )

    tableView.registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
  }

  func reloadEpisodes() {
    if let podcast = podcast {
      episodes = podcast.episodes

      // Global All | New filter
      episodes = episodes.filter({ episode -> Bool in
        if filter == .New {
          return !episode.played
        } else {
          return true
        }
      })

      // Filter based on possible search query
      if let query = searchQuery {
        episodes = episodes.filter({ episode -> Bool in
          let description = episode.description ?? ""
          return episode.title.lowercased().contains(query) || description.lowercased().contains(query)
        })
      }

      episodes.sort(by: { (a, b) -> Bool in
        switch sortBy {
        case .EpisodeMostRecent:
          guard let aD = a.pubDate else { return false }
          guard let bD = b.pubDate else { return true }

          return aD.compare(bD) == .orderedAscending
        case .EpisodeFavourites:
          return (a.favourite ? 1 : 0) < (b.favourite ? 1 : 0)
        }
      })

      if sortDirection == .Desc {
        episodes.reverse()
      }
    }

    // Handle an empty table
    if episodes.isEmpty {
    }

    let selectedRow = tableView.selectedRow
    tableView.reloadData()
    tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
  }

  func reloadEpisode(_ episode: Episode) {
    if let index = episodes.firstIndex(where: { e -> Bool in
      e.id == episode.id
    }) {
      tableView.reloadData(forRowIndexes: IndexSet.init(integer: index), columnIndexes: IndexSet.init(integer: 0))
    }
  }

  func selectPodcast(_ selectedPodcast: Podcast?) {
    podcast = selectedPodcast

    reloadEpisodes()

    // Clear selection and reset table state
    tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
    tableView.scrollRowToVisible(0)
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

  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    viewController.selectEpisode(episode: episodes[row])
    return true
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
        Library.global.save(podcast: podcast)
      })
    }

    return true
  }

  func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    // Implement -[NSTableViewDelegate tableView:heightOfRow:] to fix an issue
    // that the bottom inset of NSTableView disappears on macOS Monterey.
    return tableView.rowHeight
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
      let markedAsFavouritecount = episodes.filter({ $0.favourite }).count
      let allMarkedAsFavourite = markedAsFavouritecount == episodes.count
      let allMarkedAsUnFavourite = markedAsFavouritecount == 0

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
    if let sortParam = EpisodeSortParameter(rawValue: by ?? "") {
      sortBy = sortParam
    }

    sortDirection = direction

    reloadEpisodes()
  }

  // MARK: - Actions

  @IBAction func episodeDoubleClicked(_ sender: Any) {
    guard tableView.clickedRow != -1, tableView.clickedRow < episodes.count else {
      return
    }

    let episode = episodes[tableView.clickedRow]
    Player.global.play(episode: episode)
  }

  @IBAction @objc func playNow(_ sender: Any) {
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

    for episode in episodes {
      episode.played = shouldMarkPlayed
      Library.global.save(episode: episode)
    }
  }

  @IBAction func toggleFavourite(_ sender: Any) {
    let episodes = activeEpisodesForAction()
    let favouriteCount = episodes.filter({ $0.favourite }).count
    let allMarkedAsFavourite = favouriteCount == episodes.count

    let shouldMarkAsFavourite = !allMarkedAsFavourite

    for episode in activeEpisodesForAction() {
      episode.favourite = shouldMarkAsFavourite
      Library.global.save(episode: episode)
    }
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
