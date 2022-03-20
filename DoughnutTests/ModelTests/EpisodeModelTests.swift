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

final class EpisodeModelTests: ModelTestCase {

  private func fetchEpisode(withId id: Int64) throws -> Episode {
    let episode: Episode = try dbQueue.inDatabase { db in
      guard let episode = try Episode.fetchOne(db, key: id) else {
        XCTFail("Episode.fetchOne(_:) returns nil.")
        return nil
      }
      return episode
    }!
    return episode
  }

  func testReadEpisodeFromDB() {
    do {
      let episode: Episode = try dbQueue.inDatabase { db in
        guard let episode = try Episode.fetchOne(db, key: 1) else {
          XCTFail("Episode.fetchOne(_:) returns nil.")
          return nil
        }
        return episode
      }!

      let dateFormatter = ISO8601DateFormatter()

      XCTAssertEqual(episode.id, 1)
      XCTAssertEqual(episode.podcastId, 1)
      XCTAssertEqual(episode.title, "Test Podcast Episode #2")
      XCTAssertEqual(episode.description, "Lorem ipsum sit amet dolor")
      XCTAssertEqual(episode.guid, "https://github.com/dyerc/Doughnut#2")
      XCTAssertEqual(episode.pubDate, dateFormatter.date(from: "2017-09-25T23:30:07Z"))
      XCTAssertEqual(episode.link, "https://cdyer.co.uk")
      XCTAssertEqual(episode.enclosureUrl, "enclosure.mp3")
      XCTAssertEqual(episode.enclosureSize, 1037273)
      XCTAssertEqual(episode.fileName, "Lorem ipsum sit amet dolor")
      XCTAssertEqual(episode.favourite, true)
      XCTAssertEqual(episode.downloaded, true)
      XCTAssertEqual(episode.played, true)
      XCTAssertEqual(episode.playPosition, 708)
      XCTAssertEqual(episode.duration, 3221)
    } catch {
      XCTFail("\(#function) fail with error: \(error)")
    }
  }

  func testWriteEpisodeToDB() {
    do {
      let episodeRead = try fetchEpisode(withId: 1)

      episodeRead.id = nil
      try dbQueue.write{ db in
        try episodeRead.insert(db)
      }

      let episodeSaved = try fetchEpisode(withId: 4)

      XCTAssertEqual(episodeSaved.id, 4)
      XCTAssertEqual(episodeSaved.podcastId, episodeRead.podcastId)
      XCTAssertEqual(episodeSaved.title, episodeRead.title)
      XCTAssertEqual(episodeSaved.description, episodeRead.description)
      XCTAssertEqual(episodeSaved.guid, episodeRead.guid)
      XCTAssertEqual(episodeSaved.pubDate, episodeRead.pubDate)
      XCTAssertEqual(episodeSaved.link, episodeRead.link)
      XCTAssertEqual(episodeSaved.enclosureUrl, episodeRead.enclosureUrl)
      XCTAssertEqual(episodeSaved.enclosureSize, episodeRead.enclosureSize)
      XCTAssertEqual(episodeSaved.fileName, episodeRead.fileName)
      XCTAssertEqual(episodeSaved.favourite, episodeRead.favourite)
      XCTAssertEqual(episodeSaved.downloaded, episodeRead.downloaded)
      XCTAssertEqual(episodeSaved.played, episodeRead.played)
      XCTAssertEqual(episodeSaved.playPosition, episodeRead.playPosition)
      XCTAssertEqual(episodeSaved.duration, episodeRead.duration)
    } catch {
      XCTFail("\(#function) fail with error: \(error)")
    }
  }

}
