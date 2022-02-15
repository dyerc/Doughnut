//
//  DoughnutUITests.swift
//  DoughnutUITests
//
//  Created by Chris Dyer on 22/09/2017.
//  Copyright © 2017 Chris Dyer. All rights reserved.
//

import XCTest

@testable import Doughnut

class DoughnutUITests: XCTestCase {
  override func setUp() {
    super.setUp()

    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    let app = XCUIApplication()
    app.launchArguments += ["UI-TEST"]
    app.launch()
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testNewPodcast() {

  }
}
