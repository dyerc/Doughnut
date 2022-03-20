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

import XCTest

@testable import Doughnut

class LibraryTestCase: DoughnutTestCase {

  override func setUp() {
    super.setUp()

    XCTAssertEqual(Library.global.connect(), true)
    print("Using library at \(Library.global.path)")
  }

  override func tearDown() {
    super.tearDown()

    do {
      try Library.global.dbQueue?.inDatabase({ db in
        try Podcast.deleteAll(db)
        try Episode.deleteAll(db)
      })
    } catch let error as NSError {
      fatalError("Failed to remove database \(error.debugDescription)")
    }
  }

}
