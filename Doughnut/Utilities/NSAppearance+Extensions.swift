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

extension NSAppearance {

  var isDarkMode: Bool {
    return bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
  }

  // https://stackoverflow.com/questions/52504872/updating-for-dark-mode-nscolor-ignores-appearance-changes
  static func withAppAppearance<T>(_ closure: () throws -> T) rethrows -> T {
    let previousAppearance = NSAppearance.current
    NSAppearance.current = NSApp.effectiveAppearance
    defer {
      NSAppearance.current = previousAppearance
    }
    return try closure()
  }

}
