//
//  File.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 15/10/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

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
