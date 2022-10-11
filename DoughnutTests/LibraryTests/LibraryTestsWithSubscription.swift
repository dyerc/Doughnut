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

class LibraryTestsWithSubscription: LibraryTestCase {
  var library: Library?
  var sub: Podcast?

  override func setUp() {
    super.setUp()

    // Setup an initial podcast subscription
    let expectation = self.expectation(description: "Library has subscribed")
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.subscribedToPodcastExpectation = expectation

    Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    self.waitForExpectations(timeout: 10) { _ in
      self.sub = spy.subscribedToPodcastResult
    }
  }

  func testReloadWhenNoNewEpisodesExist() {
    XCTAssertEqual(sub!.episodes.count, 2)
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")

    Library.global.reload(podcast: sub!)

    self.waitForExpectations(timeout: 10) { _ in
      let podcasts = spy.updatedPodcastResults
      XCTAssertEqual(podcasts.count, 1)
      XCTAssertEqual(podcasts.first!.episodes.count, 2)
    }
  }

  func testReloadWhenNewEpisodesExist() {
    XCTAssertEqual(sub!.episodes.count, 2)
    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")

    // Silently change podcast feed
    sub!.feed = fixtureURL("ValidFeedx3", type: "xml").absoluteString
    do {
      try Library.global.dbQueue?.inDatabase { db in
        try sub!.save(db)
      }
    } catch {}

    Library.global.reload(podcast: sub!)

    self.waitForExpectations(timeout: 10) { _ in
      let podcasts = spy.updatedPodcastResults

      XCTAssertEqual(podcasts.count, 1)

      let podcast = podcasts.first!

      XCTAssertEqual(podcast.episodes.count, 3)

      // Ensure new episodes are linked back to podcast
      do {
        try Library.global.dbQueue?.inDatabase({ db in
          try XCTAssertEqual(Episode.filter(Column("podcast_id") == podcast.id).fetchCount(db), 3)
        })
      } catch {
        XCTFail()
      }
    }
  }

  func testUnsubscribeLeaveDownloads() {
    guard let podcast = sub else { XCTFail(); return }
    guard let storagePath = podcast.storagePath() else { XCTFail(); return }

    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.unsubscribedPodcastExpectation = self.expectation(description: "Library unsubscribed podcast")

    XCTAssertEqual(Library.global.podcasts.contains(where: { p -> Bool in
      p.id == podcast.id
    }), true)

    var isDir = ObjCBool(true)
    XCTAssertEqual(FileManager.default.fileExists(atPath: storagePath.path, isDirectory: &isDir), true)

    Library.global.unsubscribe(podcast: podcast)

    self.waitForExpectations(timeout: 10) { _ in
      XCTAssertEqual(Library.global.podcasts.count, 0)

      do {
        try Library.global.dbQueue?.inDatabase { db in
          let podcastCount = try Podcast.fetchCount(db)
          XCTAssertEqual(podcastCount, 0)
        }
      } catch {
        XCTFail()
      }

      XCTAssertEqual(FileManager.default.fileExists(atPath: storagePath.path, isDirectory: &isDir), true)
    }
  }

  func testUnsubscribeRemoveDownloads() {
    guard let podcast = sub else { XCTFail(); return }
    guard let storagePath = podcast.storagePath() else { XCTFail(); return }

    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.unsubscribedPodcastExpectation = self.expectation(description: "Library unsubscribed podcast")

    XCTAssertEqual(Library.global.podcasts.contains(where: { p -> Bool in
      p.id == podcast.id
    }), true)

    var isDir = ObjCBool(true)
    XCTAssertEqual(FileManager.default.fileExists(atPath: storagePath.path, isDirectory: &isDir), true)

    Library.global.unsubscribe(podcast: podcast, removeFiles: true)

    self.waitForExpectations(timeout: 10) { _ in
      XCTAssertEqual(Library.global.podcasts.count, 0)

      do {
        try Library.global.dbQueue?.inDatabase { db in
          let podcastCount = try Podcast.fetchCount(db)
          XCTAssertEqual(podcastCount, 0)
        }
      } catch {
        XCTFail()
      }

      sleep(1)
      XCTAssertEqual(FileManager.default.fileExists(atPath: storagePath.path, isDirectory: &isDir), false)
    }
  }

  func testSavePodcast() {
    guard let podcast = sub else { XCTFail(); return }

    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedPodcastExpectation = self.expectation(description: "Library updated podcast")

    podcast.title = "This is the new title"
    Library.global.update(podcast: podcast)

    self.waitForExpectations(timeout: 10) { _ in
      XCTAssertEqual(Library.global.podcasts.first?.title, "This is the new title")

      do {
        try Library.global.dbQueue?.inDatabase { db in
          let updated = try Podcast.fetchOne(db)
          XCTAssertEqual(updated?.title, "This is the new title")
        }
      } catch {
        XCTFail()
      }
    }
  }

  func testSaveEpisode() {
    guard let episode = sub?.episodes.first else { XCTFail(); return }

    let spy = LibrarySpyDelegate()
    Library.global.delegate = spy
    spy.updatedEpisodeExpectation = self.expectation(description: "Library updated episode")

    episode.title = "This is the new episode"
    Library.global.save(episode: episode)

    self.waitForExpectations(timeout: 10) { _ in
      XCTAssertEqual(Library.global.podcasts.first?.episodes.first?.title, "This is the new episode")

      do {
        try Library.global.dbQueue?.inDatabase { db in
          let updated = try Episode.filter(Column("id") == episode.id).fetchOne(db)
          XCTAssertEqual(updated?.title, "This is the new episode")
        }
      } catch {
        XCTFail()
      }
    }
  }
}
