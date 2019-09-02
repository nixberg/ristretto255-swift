import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ElementTests.allTests),
        testCase(FieldElementTests.allTests),
        testCase(ScalarTests.allTests),
    ]
}
#endif
