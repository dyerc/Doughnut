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

enum SortDirection: String, CaseIterable {
  case asc = "Ascending"
  case desc = "Descending"
}

protocol SortingMenuProviderDelegate {

  func sorted(by: String?, direction: SortDirection)

}

final class SortingMenuProvider {

  struct Shared {
    static let podcasts = SortingMenuProvider(
      menuItemTitles: [
        PodcastViewController.SortParameter.title.rawValue,
        PodcastViewController.SortParameter.episodes.rawValue,
        PodcastViewController.SortParameter.favourites.rawValue,
        PodcastViewController.SortParameter.recentEpisodes.rawValue,
        PodcastViewController.SortParameter.unplayed.rawValue,
      ]
    )
    static let episodes = SortingMenuProvider(
      menuItemTitles: [
        EpisodeViewController.SortParameter.favourites.rawValue,
        EpisodeViewController.SortParameter.mostRecent.rawValue,
      ]
    )
  }

  var delegate: SortingMenuProviderDelegate?

  var menuItemTitles: [String]

  init(menuItemTitles: [String]) {
    self.menuItemTitles = menuItemTitles
  }

  func buildMenu() -> NSMenu {
    return internalBuildMenu(isPullDownMenu: false)
  }

  func buildPullDownMenu() -> NSMenu {
    return internalBuildMenu(isPullDownMenu: true)
  }

  private func internalBuildMenu(isPullDownMenu: Bool) -> NSMenu {
    let sortMenu = NSMenu()

    let titleItems: [NSMenuItem] = menuItemTitles.map { title in
      let item = NSMenuItem(title: title, action: #selector(performSort), keyEquivalent: "")
      item.target = self

      if title == sortParam {
        item.state = .on
      }
      return item
    }

    let directionMenuItems: [NSMenuItem] = SortDirection.allCases.map { direction in
      let item = NSMenuItem(title: direction.rawValue, action: #selector(performSortDirection), keyEquivalent: "")
      item.target = self

      if direction == sortDirection {
        item.state = .on
      }
      return item
    }

    if isPullDownMenu {
      // Title item for pull-down button
      sortMenu.addItem(NSMenuItem(title: "Sort by \(sortParam ?? "Unknown")", action: nil, keyEquivalent: ""))
    }

    for item in titleItems {
      sortMenu.addItem(item)
    }

    sortMenu.addItem(NSMenuItem.separator())

    for item in directionMenuItems {
      sortMenu.addItem(item)
    }

    if isPullDownMenu {
      // Ensure menuItems' title font is consistent with normal menus for
      // recessed pull-down button.
      for item in sortMenu.items[1...] {
        item.attributedTitle = NSAttributedString(
          string: item.title,
          attributes: [
            .font: NSFont.controlContentFont(ofSize: NSFont.systemFontSize),
          ]
        )
      }
    }

    return sortMenu
  }

  var sortParam: String?

  @objc func performSort(_ sender: NSMenuItem) {
    sortParam = sender.title
    delegate?.sorted(by: sortParam, direction: sortDirection)
  }

  var sortDirection: SortDirection = .asc

  @objc func performSortDirection(_ sender: NSMenuItem) {
    guard let sortDirection = SortDirection(rawValue: sender.title) else {
      return
    }
    self.sortDirection = sortDirection
    delegate?.sorted(by: sortParam, direction: sortDirection)
  }

}
