import XCTest
@testable import Ristretto255

fileprivate let aBytes: [UInt8] = [
    0x04, 0xfe, 0xdf, 0x98, 0xa7, 0xfa, 0x0a, 0x68,
    0x84, 0x92, 0xbd, 0x59, 0x08, 0x07, 0xa7, 0x03,
    0x9e, 0xd1, 0xf6, 0xf2, 0xe1, 0xd9, 0xe2, 0xa4,
    0xa4, 0x51, 0x47, 0x36, 0xf3, 0xc3, 0xa9, 0x17
]

fileprivate let aSquaredBytes: [UInt8] = [
    0x75, 0x97, 0x24, 0x9e, 0xe6, 0x06, 0xfe, 0xab,
    0x24, 0x04, 0x56, 0x68, 0x07, 0x91, 0x2d, 0x5d,
    0x0b, 0x0f, 0x3f, 0x1c, 0xb2, 0x6e, 0xf2, 0xe2,
    0x63, 0x9c, 0x12, 0xba, 0x73, 0x0b, 0xe3, 0x62
]

fileprivate let aPow2252MinusThreeBytes: [UInt8] = [
    0x6a, 0x4f, 0x24, 0x89, 0x1f, 0x57, 0x60, 0x36,
    0xd0, 0xbe, 0x12, 0x3c, 0x8f, 0xf5, 0xb1, 0x59,
    0xe0, 0xf0, 0xb8, 0x1b, 0x20, 0xd2, 0xb5, 0x1f,
    0x15, 0x21, 0xf9, 0xe3, 0xe1, 0x61, 0x21, 0x55
]

fileprivate let aInvertedBytes: [UInt8] = [
    0x96, 0x1b, 0xcd, 0x8d, 0x4d, 0x5e, 0xa2, 0x3a,
    0xe9, 0x36, 0x37, 0x93, 0xdb, 0x7b, 0x4d, 0x70,
    0xb8, 0x0d, 0xc0, 0x55, 0xd0, 0x4c, 0x1d, 0x7b,
    0x90, 0x71, 0xd8, 0xe9, 0xb6, 0x18, 0xe6, 0x30
]

final class FieldElementTest: XCTestCase {
    func testRoundtrip() {
        let one = FieldElement(from: [
            0xee, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f
        ])
        let oneBytes = one.encoded()
        
        XCTAssertEqual(oneBytes[0], 0x01)
        for byte in oneBytes.suffix(31) {
            XCTAssertEqual(byte, 0x00)
        }
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
        XCTAssertEqual(FieldElement(from: highBitSet), FieldElement(from: highBitCleared))
    }
    
    func testNegationAndAbs() {
        let a = FieldElement(from: aBytes)
        XCTAssertEqual(a, -(-a))
        XCTAssertEqual(a, abs(-a))
    }
    
    func testMultiplication() {
        let a = FieldElement(from: aBytes)
        let aSquare = FieldElement(from: aSquaredBytes)
        XCTAssertEqual(a * a, aSquare)
    }
    
    func testSquaring() {
        let a = FieldElement(from: aBytes)
        let aSquared = FieldElement(from: aSquaredBytes)
        XCTAssertEqual(a.squared(), aSquared)
    }
    
    func testPowP5Over8() {
        let a = FieldElement(from: aBytes)
        let aPow2252MinusThree = FieldElement(from: aPow2252MinusThreeBytes)
        XCTAssertEqual(a.pow2252MinusThree(), aPow2252MinusThree)
    }
    
    func testInversion() {
        let a = FieldElement(from: aBytes)
        let aInverted = FieldElement(from: aInvertedBytes)
        XCTAssertEqual(a.inverted(), aInverted)
        XCTAssertEqual(a.inverted().inverted(), a)
    }
    
    func testSquareRoot() {
        var (wasSquare, squareRoot) = 0.squareRoot(over: 0)
        XCTAssert(Bool(wasSquare))
        XCTAssertEqual(squareRoot, 0)
        XCTAssert(Bool(squareRoot.isPositive()))
        
        (wasSquare, squareRoot) = 1.squareRoot(over: 0)
        XCTAssert(Bool(!wasSquare))
        XCTAssertEqual(squareRoot, 0)
        XCTAssert(Bool(squareRoot.isPositive()))
        
        (wasSquare, squareRoot) = 2.squareRoot(over: 1)
        XCTAssert(Bool(!wasSquare))
        XCTAssertEqual(squareRoot.squared(), squareRootMinusOne * 2)
        XCTAssert(Bool(squareRoot.isPositive()))
        
        (wasSquare, squareRoot) = 4.squareRoot(over: 1)
        XCTAssert(Bool(wasSquare))
        XCTAssertEqual(squareRoot.squared(), 4)
        XCTAssert(Bool(squareRoot.isPositive()))
        
        (wasSquare, squareRoot) = 1.squareRoot(over: 4)
        XCTAssert(Bool(wasSquare))
        XCTAssertEqual(squareRoot.squared() * 4, 1)
        XCTAssert(Bool(squareRoot.isPositive()))
    }
}

extension FieldElement: Equatable {
    public static func == (lhs: FieldElement, rhs: FieldElement) -> Bool {
        Bool(CTBool(lhs == rhs))
    }
}

extension FieldElement: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt8
    
    public init(integerLiteral value: UInt8) {
        self = FieldElement(UInt64(value))
    }
}

fileprivate extension Int {
    func squareRoot(over v: FieldElement) -> (CTBool, FieldElement) {
        FieldElement(UInt64(self)).squareRoot(over: v)
    }
}
