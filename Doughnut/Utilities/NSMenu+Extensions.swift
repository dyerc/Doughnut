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

import AppKit

extension NSMenu {

  enum MenuType {
    case main
    case dock
    case contextual
  }

  var menuType: MenuType {
    let topMenu = topMenu
    if topMenu == NSApp.mainMenu {
      return .main
    } else if topMenu == NSApp.delegate?.applicationDockMenu?(NSApp) {
      return .dock
    } else {
      return .contextual
    }
  }

  var topMenu: NSMenu {
    var current: NSMenu? = self
    while current?.supermenu != nil {
      current = current?.supermenu
    }
    return current!
  }

  var menuItem: NSMenuItem? {
    return supermenu?.items.first {
      $0.submenu == self
    }
  }

}

extension NSMenuItem {

  var topMenu: NSMenu? {
    return menu?.topMenu
  }

  var menuType: NSMenu.MenuType? {
    return menu?.menuType
  }

  func configureWithDefaultFont() {
    attributedTitle = NSAttributedString(
      string: title,
      attributes: [
        .font: NSFont.controlContentFont(ofSize: NSFont.systemFontSize),
      ]
    )
  }

}
