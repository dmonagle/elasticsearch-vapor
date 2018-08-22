import XCTest

import elasticsearch_nioTests

var tests = [XCTestCaseEntry]()
tests += elasticsearch_nioTests.allTests()
XCTMain(tests)