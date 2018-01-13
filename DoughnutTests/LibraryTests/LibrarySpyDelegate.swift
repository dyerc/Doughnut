//
//  LibrarySpyDelegate.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 13/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut

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
  var updatedPodcastResult: Podcast?
  func libraryUpdatedPodcast(podcast: Podcast) {
    guard let expectation = updatedPodcastExpectation else { return }
    updatedPodcastResult = podcast
    expectation.fulfill()
  }
  
  var updatedEpisodeExpectation: XCTestExpectation?
  var updatedEpisodeResult: Episode?
  func libraryUpdatedEpisode(episode: Episode) {
    guard let expectation = updatedEpisodeExpectation else { return }
    updatedEpisodeResult = episode
    expectation.fulfill()
  }
  
  var unsubscribedPodcastExpectation: XCTestExpectation?
  var unsubscribedPodcastResult: Podcast?
  func libraryUnsubscribedFromPodcast(unsubscribed: Podcast) {
    guard let expectation = unsubscribedPodcastExpectation else { return }
    unsubscribedPodcastResult = unsubscribed
    expectation.fulfill()
  }
  
  func libraryUpdatingPodcast(podcast: Podcast) {
    
  }
}
