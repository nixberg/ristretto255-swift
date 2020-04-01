import XCTest
@testable import Ristretto255

final class FieldElementTest: XCTestCase {
    private let a = FieldElement(from: [
        0x04, 0xfe, 0xdf, 0x98, 0xa7, 0xfa, 0x0a, 0x68,
        0x84, 0x92, 0xbd, 0x59, 0x08, 0x07, 0xa7, 0x03,
        0x9e, 0xd1, 0xf6, 0xf2, 0xe1, 0xd9, 0xe2, 0xa4,
        0xa4, 0x51, 0x47, 0x36, 0xf3, 0xc3, 0xa9, 0x17
    ])!
    
    private let aSquared = FieldElement(from: [
        0x75, 0x97, 0x24, 0x9e, 0xe6, 0x06, 0xfe, 0xab,
        0x24, 0x04, 0x56, 0x68, 0x07, 0x91, 0x2d, 0x5d,
        0x0b, 0x0f, 0x3f, 0x1c, 0xb2, 0x6e, 0xf2, 0xe2,
        0x63, 0x9c, 0x12, 0xba, 0x73, 0x0b, 0xe3, 0x62
    ])!
    
    func testRoundtrip() {
        let one = FieldElement(canonicalizing: [0xee] + [UInt8](repeating: 0xff, count: 30) + [0x7f])
        let expected = [0x01] + [UInt8](repeating: 0x00, count: 31)
        XCTAssertEqual(one.encoded(), expected)
        XCTAssertEqual(FieldElement.one.encoded(), expected)
    }
    
    func testHighBitIgnored() {
        let highBitSet: [UInt8] = [
            0x71, 0xbf, 0xa9, 0x8f, 0x5b, 0xea, 0x79, 0x0f,
            0xf1, 0x83, 0xd9, 0x24, 0xe6, 0x65, 0x5c, 0xea,
            0x08, 0xd0, 0xaa, 0xfb, 0x61, 0x7f, 0x46, 0xd2,
            0x3a, 0x17, 0xa6, 0x57, 0xf0, 0xa9, 0xb8, 0xb2
        ]
        var highBitCleared = highBitSet
        highBitCleared[31] &= 0b0111_1111
        XCTAssertEqual(FieldElement(canonicalizing: highBitSet), FieldElement(from: highBitCleared))
    }
    
    func testNegationAndAbs() {
        XCTAssertEqual(-(-a), a)
        XCTAssertEqual(abs(-a), a)
    }
    
    func testMultiplication() {
        XCTAssertEqual(a * a, aSquared)
    }
    
    func testSquaring() {
        XCTAssertEqual(a.squared(), aSquared)
    }
    
    func testPowTwo252MinusThree() {
        let expected = FieldElement(from: [
            0x6a, 0x4f, 0x24, 0x89, 0x1f, 0x57, 0x60, 0x36,
            0xd0, 0xbe, 0x12, 0x3c, 0x8f, 0xf5, 0xb1, 0x59,
            0xe0, 0xf0, 0xb8, 0x1b, 0x20, 0xd2, 0xb5, 0x1f,
            0x15, 0x21, 0xf9, 0xe3, 0xe1, 0x61, 0x21, 0x55
        ])
        XCTAssertEqual(a.powTwo252MinusThree(), expected)
    }
    
    func testInversion() {
        let expected = FieldElement(from: [
            0x96, 0x1b, 0xcd, 0x8d, 0x4d, 0x5e, 0xa2, 0x3a,
            0xe9, 0x36, 0x37, 0x93, 0xdb, 0x7b, 0x4d, 0x70,
            0xb8, 0x0d, 0xc0, 0x55, 0xd0, 0x4c, 0x1d, 0x7b,
            0x90, 0x71, 0xd8, 0xe9, 0xb6, 0x18, 0xe6, 0x30
        ])
        XCTAssertEqual(a.inverted(), expected)
        XCTAssertEqual(a.inverted().inverted(), a)
    }
    
    func testSquareRoot() {
        var (squareRoot, wasSquare) = 0.squareRoot(over: 0)
        XCTAssertTrue(Bool(wasSquare))
        XCTAssertEqual(squareRoot, 0)
        XCTAssertFalse(Bool(squareRoot.isNegative()))
        
        (squareRoot, wasSquare) = 1.squareRoot(over: 0)
        XCTAssertFalse(Bool(wasSquare))
        XCTAssertEqual(squareRoot, 0)
        XCTAssertFalse(Bool(squareRoot.isNegative()))
        
        (squareRoot, wasSquare) = 2.squareRoot(over: 1)
        XCTAssertFalse(Bool(wasSquare))
        XCTAssertEqual(squareRoot.squared(), 2 * squareRootMinusOne)
        XCTAssertFalse(Bool(squareRoot.isNegative()))
        
        (squareRoot, wasSquare) = 4.squareRoot(over: 1)
        XCTAssertTrue(Bool(wasSquare))
        XCTAssertEqual(squareRoot.squared(), 4)
        XCTAssertFalse(Bool(squareRoot.isNegative()))
        
        (squareRoot, wasSquare) = 1.squareRoot(over: 4)
        XCTAssertTrue(Bool(wasSquare))
        XCTAssertEqual(4 * squareRoot.squared(), 1)
        XCTAssertFalse(Bool(squareRoot.isNegative()))
    }
}

extension FieldElement: Equatable {
    public static func == (lhs: FieldElement, rhs: FieldElement) -> Bool {
        Bool(CTBool(lhs == rhs))
    }
}

extension FieldElement: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt64
    
    public init(integerLiteral value: UInt64) {
        self = FieldElement(value, 0, 0, 0, 0)
    }
}

fileprivate extension Int {
    func squareRoot(over v: FieldElement) -> (result: FieldElement, wasSquare: CTBool) {
        FieldElement(UInt64(self), 0, 0, 0, 0).squareRoot(over: v)
    }
}
