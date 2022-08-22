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

import Foundation
import OSLog

extension OSLog {

  static func main(category: String) -> OSLog {
    return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: category)
  }

  // This is a compromised approach since `os.Logger` and `os.OSLogMessage` 
  // requires macOS 11.0.
  // See also: https://stackoverflow.com/questions/53025698#62488271
  // TODO: Migrate to `os.Logger` when we drop the support for 10.15 (Catalina).
  func callAsFunction(level: OSLogType, _ s: String) {
    os_log(level, log: self, "%{public}s", s)
  }

}
