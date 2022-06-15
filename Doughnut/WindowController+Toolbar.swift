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

private extension NSToolbarItem.Identifier {

  static let doughnutRefresh     = Self("NSToolbarDoughnutRefreshItemIdentifier")
  static let doughnutNewPodcast  = Self("NSToolbarDoughnutNewPodcastItemIdentifier")
  static let doughnutFilter      = Self("NSToolbarDoughnutFilterItemIdentifier")
  static let doughnutPlayerView  = Self("NSToolbarDoughnutPlayerViewItemIdentifier")
  static let doughnutTaskManager = Self("NSToolbarDoughnutTaskManagerItemIdentifier")
  static let doughnutSearch      = Self("NSToolbarDoughnutSearchItemIdentifier")

}

extension WindowController: NSToolbarDelegate {

  private static let fixedSizeIdentifiersForCatalina: [NSToolbarItem.Identifier] = [
    .doughnutRefresh,
    .doughnutNewPodcast,
  ]

  private static let itemsToHideMenu: [NSToolbarItem.Identifier] = [
    .doughnutTaskManager,
    .doughnutPlayerView,
  ]

  private static let fixedItemSizeForCatalina = CGSize(width: 40, height: 23)

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    if #available(macOS 11.0, *) {
      return [
        .flexibleSpace,
        .doughnutRefresh,
        .doughnutNewPodcast,
        .sidebarTrackingSeparator,
        .flexibleSpace,
        .doughnutFilter,
        .doughnutPlayerView,
        .doughnutTaskManager,
        .flexibleSpace,
        .doughnutSearch,
      ]
    } else {
      return [
        .doughnutRefresh,
        .doughnutNewPodcast,
        .flexibleSpace,
        .doughnutPlayerView,
        .doughnutTaskManager,
        .flexibleSpace,
        .doughnutSearch,
      ]
    }
  }

  func toolbarWillAddItem(_ notification: Notification) {
    guard let item = notification.userInfo?["item"] as? NSToolbarItem else {
      return
    }

    if #available(macOS 11.0, *) { } else {
      if Self.fixedSizeIdentifiersForCatalina.contains(item.itemIdentifier) {
        item.minSize = Self.fixedItemSizeForCatalina
        item.maxSize = Self.fixedItemSizeForCatalina
      }
    }

    if Self.itemsToHideMenu.contains(item.itemIdentifier) {
      item.menuFormRepresentation = nil
    }
  }

}
