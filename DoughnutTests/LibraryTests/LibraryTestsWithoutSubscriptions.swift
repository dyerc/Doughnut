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

class LibraryTestsWithoutSubscription: LibraryTestCase {
  var library: Library?

  func testSubscribe() {
    let expectation = self.expectation(description: "Library calls didSubscribeToPodcast")
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.subscribedToPodcastExpectation = expectation

    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)

    self.waitForExpectations(timeout: 1) { error in
      if let error = error {
        XCTFail("\(error)")
      }

      guard let sub = spy.subscribedToPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }

      XCTAssertEqual(sub.title, "Test Feed")
      XCTAssertEqual(sub.author, "dyerc")
      XCTAssertGreaterThan(sub.id!, 0)
      XCTAssertEqual(sub.episodes.count, 2)

      let pod = Library.global.podcast(id: sub.id!)
      XCTAssertEqual(pod!.title, sub.title)
    }
  }

  func testSubscribeWithoutFeed() {
    let expectation = self.expectation(description: "Library calls didSubscribeToPodcast")
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.subscribedToPodcastExpectation = expectation

    let podcast = Podcast(title: "New Podcast")
    podcast.author = "No Feed"

    Library.global.subscribe(podcast: podcast)

    self.waitForExpectations(timeout: 1) { error in
      if let error = error {
        XCTFail("\(error)")
      }

      guard let sub = spy.subscribedToPodcastResult else {
        XCTFail("Expected delegate to be called")
        return
      }

      XCTAssertEqual(sub.title, "New Podcast")
      XCTAssertEqual(sub.author, "No Feed")
      XCTAssertGreaterThan(sub.id!, 0)
      XCTAssertEqual(sub.episodes.count, 0)

      let pod = Library.global.podcast(id: sub.id!)
      XCTAssertEqual(pod!.title, sub.title)
    }
  }

  func testSanitizeFilePath() {

  }
}
