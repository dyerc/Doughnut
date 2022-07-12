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

class LibrarySpyDelegate: LibraryDelegate {
  var subscribedToPodcastExpectation: XCTestExpectation?
  var subscribedToPodcastResult: Podcast?
  func librarySubscribedToPodcast(subscribed: Podcast) {
    guard let expectation = subscribedToPodcastExpectation else { return }
    self.subscribedToPodcastResult = subscribed
    expectation.fulfill()
  }

  func libraryReloaded() {

  }

  var updatedPodcastExpectation: XCTestExpectation?
  var updatedPodcastResults = [Podcast]()
  func libraryUpdatedPodcasts(podcasts: [Podcast]) {
    guard let expectation = updatedPodcastExpectation else { return }
    updatedPodcastResults = podcasts
    expectation.fulfill()
  }

  var updatedEpisodeExpectation: XCTestExpectation?
  var updatedEpisodeResults = [Episode]()
  func libraryUpdatedEpisodes(episodes: [Episode]) {
    guard let expectation = updatedEpisodeExpectation else { return }
    updatedEpisodeResults = episodes
    expectation.fulfill()
  }

  var unsubscribedPodcastExpectation: XCTestExpectation?
  var unsubscribedPodcastResult: Podcast?
  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    guard let expectation = unsubscribedPodcastExpectation else { return }
    unsubscribedPodcastResult = unsubscribed
    expectation.fulfill()
  }

  func libraryUpdatingPodcasts(podcasts: [Podcast]) {

  }
}
