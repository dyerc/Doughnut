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
import XCTest

@testable import Doughnut

class LibraryUtils: XCTestCase {
  func testExtractsItunesPodcastId() {
    XCTAssertEqual(Utils.iTunesPodcastId(iTunesUrl: "https://itunes.apple.com/gb/podcast/tell-em-steve-dave/id357537542?mt=2"), "357537542")
  }

  func testExtractsFeedUrlFromItunes() {
    let exp = expectation(description: "Parses iTunes data")

    _ = Utils.iTunesFeedUrl(iTunesUrl: "https://itunes.apple.com/gb/podcast/tell-em-steve-dave/id357537542?mt=2") { feedUrl in
      XCTAssertEqual(feedUrl, "http://feeds.feedburner.com/TellEmSteveDave")
      exp.fulfill()
    }

    wait(for: [exp], timeout: 10)
  }
}
