import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(elasticsearch_nioTests.allTests),
    ]
}
#endif