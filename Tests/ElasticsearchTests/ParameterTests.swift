//
//  ParameterTest.swift
//  ElasticsearchVaporTests
//
//  Created by David Monagle on 22/8/18.
//

import XCTest
import ElasticsearchVapor

class ParameterTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultValue() {
        let params : ESDictionary = ["one": "1", "two": 2]
        
        XCTAssertEqual(try params.get("one", default: "5"), "1")
        XCTAssertEqual(try params.get("three", default: "3"), "3")
    }

    func testEnforceParameter() throws {
        let params : ESDictionary = ["one": "1", "two": "2", "three": "3"]
        try _ = params.enforce("one")
        XCTAssertThrowsError(try _ = params.enforce("five"), "five should not exist")
    }
    

    func testPathify() {
        XCTAssertEqual(try! ["one/", "/", "two ", "\n", "//three"].esPathify(), "one/two/three")
        XCTAssertEqual(try! ["one/", "/", nil, "\n", "//three"].compactMap {$0}.esPathify(), "one/three")
        XCTAssertEqual(try! ["one/", "/", "", "\n", "//three"].esPathify(), "one/three")

        let indexes : [ESValue?] = ["one", "two", "three"]
        let path = try! [indexes, "_search"].esPathify()
        XCTAssertEqual(path, "one,two,three/_search")
    }

    func testListify() {
        XCTAssertEqual(try! ["A", "B"].esString(), "A,B")
        XCTAssertEqual(try! ["one", "two^three"].esString(), "one,two%5Ethree")

        let esParam : [ESValue?] = ["one", "two^three"]
        XCTAssertEqual(try! esParam.esString(), "one,two%5Ethree")

    }
//
//    func testValidateAndExtractQuery() throws {
//
//        let params : ESParams = [
//            "pretty": "true",
//            "field": "name",
//            "mine": "special"
//        ]
//
//
//        let q2 = try esClient.validateAndExtractQuery(parameters: params, include: ["mine"])
//        XCTAssertEqual(q2["mine"], "special") // The included value makes it through
//        XCTAssertEqual(q2["pretty"], "true") // Common Query Parameter makes it through
//        XCTAssertEqual(q2["field"], nil) // Common validates but will not end up in the query
//    }
}
