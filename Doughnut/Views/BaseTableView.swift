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

final class BaseTableView: NSTableView {

  override func responds(to selector: Selector!) -> Bool {
    // NSWindow converts certain keys that control UI into actions.
    // For the 'Space' menu key equivalent to work properly, we need to prevent
    // 'performClick:' from being called, so that the event has a chance to
    // propagate to the main menu.
    //
    // See https://stackoverflow.com/questions/11155239/nsmenuitem-keyequivalent-space-bug#54006299
    // for detailed explanations.
    if selector == #selector(performClick(_:)) { return false }
    return super.responds(to: selector)
  }

}
