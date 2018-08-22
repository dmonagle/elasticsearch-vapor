//
//  DatabaseTest.swift
//  ElasticsearchVaporTests
//
//  Created by David Monagle on 22/8/18.
//

import Dispatch
import XCTest
@testable import ElasticsearchVapor

class ElasticsearchDatabaseTests: XCTestCase {
    var group : EventLoopGroup!
    var database : ElasticsearchDatabase!
    
    override func setUp() {
        super.setUp()

        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.database = try! ElasticsearchDatabase()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConnection() {
        let elasticsearch = try! database.newConnection(on: group).wait()
        defer { elasticsearch.close() }
        
        let types : [ESValue] = ["http", "plugins"]
        try! elasticsearch.request(method: .GET, path: ["_nodes", types]).map { response in
            print(response.body.description)
        }.wait()
    }
}
