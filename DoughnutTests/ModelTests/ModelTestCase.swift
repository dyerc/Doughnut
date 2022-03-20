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

import GRDB

class ModelTestCase: DoughnutTestCase {

  var dbQueue: DatabaseQueue!

  override func setUp() {
    super.setUp()

    do {
      let libraryPath = Preference.libraryPath()
      let modelTestsFilePath = libraryPath.appendingPathComponent("ModelTests.dnl").path
      if FileManager.default.fileExists(atPath: modelTestsFilePath) {
        try FileManager.default.removeItem(atPath: modelTestsFilePath)
      }
      try FileManager.default.copyItem(atPath: fixtureURL("ModelTests", type: "dnl").path, toPath: modelTestsFilePath)

      dbQueue = try DatabaseQueue(path: modelTestsFilePath)
    } catch {
      fatalError("ModelTestCase: failed to setup with error: \(error)")
    }
  }

  override func tearDown() {
    super.tearDown()
  }

}
