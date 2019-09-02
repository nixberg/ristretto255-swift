import XCTest

import Ristretto255Tests

var tests = [XCTestCaseEntry]()
tests += ElementTests.allTests()
tests += FieldElementTests.allTests()
tests += ScalarTests.allTests()
XCTMain(tests)
