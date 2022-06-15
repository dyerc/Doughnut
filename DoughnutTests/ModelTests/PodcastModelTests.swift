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

final class PodcastModelTests: ModelTestCase {

  private func fetchPodcast(withId id: Int64) throws -> Podcast {
    let podcast: Podcast = try dbQueue.inDatabase { db in
      guard let podcast = try Podcast.fetchOne(db, key: id) else {
        XCTFail("Podcast.fetchOne(_:) returns nil.")
        return nil
      }
      podcast.loadEpisodes(db: db)
      return podcast
    }!
    return podcast
  }

  func testReadPodcastFromDB() {
    do {
      let podcast = try fetchPodcast(withId: 1)

      let dateFormatter = ISO8601DateFormatter()

      XCTAssertEqual(podcast.id, 1)
      XCTAssertEqual(podcast.title, "Test Feed")
      XCTAssertEqual(podcast.path, "Test Feed")
      XCTAssertEqual(podcast.feed, "http://localhost/ValidFeed.xml")
      XCTAssertEqual(podcast.description, "Lorem ipsum sit amet dolor")
      XCTAssertEqual(podcast.link, "https://cdyer.co.uk")
      XCTAssertEqual(podcast.author, "dyerc")
      XCTAssertEqual(podcast.language, "en-us")
      XCTAssertEqual(podcast.copyright, "© 2017 Chris Dyer")
      XCTAssertEqual(podcast.pubDate, dateFormatter.date(from: "2017-09-25T23:30:07Z"))

      let imageRepresentation = podcast.image?.representations.first
      XCTAssertNotNil(imageRepresentation)
      XCTAssertEqual(imageRepresentation?.pixelsHigh, 100)
      XCTAssertEqual(imageRepresentation?.pixelsWide, 100)

      XCTAssertEqual(podcast.imageUrl, "http://localhost/image.jpg")
      XCTAssertEqual(podcast.lastParsed, dateFormatter.date(from: "2022-03-20T08:09:09Z"))
      XCTAssertEqual(podcast.subscribedAt, dateFormatter.date(from: "2022-03-20T08:09:09Z"))
      XCTAssertEqual(podcast.autoDownload, true)
      XCTAssertEqual(podcast.reloadFrequency, 10)

      XCTAssertEqual(podcast.manualReload, false)
      XCTAssertEqual(podcast.defaultReload, false)

      XCTAssertEqual(podcast.episodes.map { $0.id }, [1, 2, 3])
      XCTAssertEqual(podcast.unplayedCount, 1)
      XCTAssertEqual(podcast.favouriteCount, 2)
      XCTAssertEqual(podcast.latestEpisode?.id, 3)
    } catch {
      XCTFail("\(#function) fail with error: \(error)")
    }
  }

  func testWritePodcastToDB() {
    do {
      let podcastRead = try fetchPodcast(withId: 1)

      podcastRead.id = nil
      try dbQueue.write{ db in
        try podcastRead.insert(db)
      }

      let podcastSaved = try fetchPodcast(withId: 2)

      XCTAssertEqual(podcastSaved.id, 2)
      XCTAssertEqual(podcastSaved.title, podcastRead.title)
      XCTAssertEqual(podcastSaved.path, podcastRead.path)
      XCTAssertEqual(podcastSaved.feed, podcastRead.feed)
      XCTAssertEqual(podcastSaved.description, podcastRead.description)
      XCTAssertEqual(podcastSaved.link, podcastRead.link)
      XCTAssertEqual(podcastSaved.author, podcastRead.author)
      XCTAssertEqual(podcastSaved.language, podcastRead.language)
      XCTAssertEqual(podcastSaved.copyright, podcastRead.copyright)
      XCTAssertEqual(podcastSaved.pubDate, podcastRead.pubDate)
      XCTAssertEqual(podcastSaved.image?.size, podcastRead.image?.size)
      XCTAssertEqual(podcastSaved.imageUrl, podcastRead.imageUrl)
      XCTAssertEqual(podcastSaved.lastParsed, podcastRead.lastParsed)
      XCTAssertEqual(podcastSaved.subscribedAt, podcastRead.subscribedAt)
      XCTAssertEqual(podcastSaved.autoDownload, podcastRead.autoDownload)
      XCTAssertEqual(podcastSaved.reloadFrequency, podcastRead.reloadFrequency)

      XCTAssertEqual(podcastRead.manualReload, podcastSaved.manualReload)
      XCTAssertEqual(podcastRead.defaultReload, podcastSaved.defaultReload)

      XCTAssert(podcastSaved.episodes.isEmpty)
      XCTAssertEqual(podcastSaved.unplayedCount, 0)
      XCTAssertEqual(podcastSaved.favouriteCount, 0)
      XCTAssertNil(podcastSaved.latestEpisode)
    } catch {
      XCTFail("\(#function) fail with error: \(error)")
    }
  }

}
