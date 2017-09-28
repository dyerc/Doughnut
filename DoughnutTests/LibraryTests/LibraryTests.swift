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
    let libraryPath = URL(string: NSTemporaryDirectory())?.appendingPathComponent("Doughtnut_test")
    
    Preference.createLibraryIfNotExists(libraryPath!)
    
    self.library = Library(URL(string: (libraryPath?.path)!))
    XCTAssertEqual(self.library?.connect(), true)
  }
  
  func testSubscribe() {
    let sub = library!.subscribe(url: fixtureURL("ValidFeed", type: "xml").absoluteString)
    
    XCTAssertEqual(sub!.title, "Test Feed")
    XCTAssertGreaterThan(sub!.id!, 0)
  }
}
