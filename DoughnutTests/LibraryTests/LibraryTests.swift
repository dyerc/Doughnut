//
//  LibraryTests.swift
//  DoughnutTests
//
//  Created by Chris Dyer on 27/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest
import Doughnut

class LibraryTests: BaseTestCase {
  var library: Library?
  
  override func setUp() {
    super.setUp()
    XCTAssertEqual(Library.global.connect(), true)
    print("Using library at \(Library.global.path)")
  }
  
  func testSubscribe() {
    let sub = Library.global.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    
    XCTAssertEqual(sub!.title, "Test Feed")
    XCTAssertEqual(sub!.author, "CD1212")
    XCTAssertGreaterThan(sub!.id!, 0)
    
    // Try querying it back
    let pod = Library.global.podcast(id: sub!.id!)
    XCTAssertEqual(pod!.title, sub!.title)
  }
}
