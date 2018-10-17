//
//  NodeTests.swift
//  ElasticsearchVaporTests
//
//  Created by David Monagle on 22/8/18.
//

import XCTest
@testable import ElasticsearchVapor

class ConnectionTest: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDeadTracking() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let url = URL(string: "http://localhost:9200")!
        let node = ESNode(url: url)
        XCTAssert(node.isAlive)
        node.makeDead()
        XCTAssert(node.isDead)
        XCTAssert(node.failures == 1)
        XCTAssertEqual(node.failures, 1)
        XCTAssert(!node.isResurrectable)
        node.resurrect() // This should not be able to make the connection alive as it hasn't been dead long enough
        XCTAssert(node.isDead)
        node.deadSince = Date() - 120 // Fake deadSince to be 2 minutes ago
        XCTAssert(node.isResurrectable)
        node.resurrect() // This should work now
        XCTAssert(node.isAlive)
        XCTAssertEqual(node.failures, 1) // Failures is stil 1 because the connection has not been deemed healthy
        node.makeHealthy()
        XCTAssertEqual(node.failures, 0)
        debugPrint(node)
    }
}
