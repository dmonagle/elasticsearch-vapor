import XCTest

extension ConnectionTest {
    static let __allTests = [
        ("testDeadTracking", testDeadTracking),
    ]
}

extension ElasticsearchDatabaseTests {
    static let __allTests = [
        ("testConnection", testConnection),
    ]
}

extension ParameterTest {
    static let __allTests = [
        ("testDefaultValue", testDefaultValue),
        ("testEnforceParameter", testEnforceParameter),
        ("testListify", testListify),
        ("testPathify", testPathify),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ConnectionTest.__allTests),
        testCase(ElasticsearchDatabaseTests.__allTests),
        testCase(ParameterTest.__allTests),
    ]
}
#endif
