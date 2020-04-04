import XCTest
@testable import Ristretto255

final class CTBoolTests: XCTestCase {
    func testEqualTo() {
        for lhs in UInt8.min...UInt8.max {
            for rhs in UInt8.min...UInt8.max {
                XCTAssertEqual(Bool((lhs == rhs) as CTBool), lhs == rhs)
            }
        }
    }
    
    func testLessThan() {
        for lhs in UInt8.min...UInt8.max {
            for rhs in UInt8.min...UInt8.max {
                XCTAssertEqual(Bool((lhs < rhs) as CTBool), lhs < rhs)
            }
        }
    }
}
