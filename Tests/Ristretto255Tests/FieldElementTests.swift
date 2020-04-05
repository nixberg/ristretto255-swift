import XCTest
@testable import Ristretto255

final class FieldElementTest: XCTestCase {
    let a =  FieldElement(
        0x0002faa798dffe04,
        0x00010b37b2508d01,
        0x0003db46780e9c1c,
        0x0000d252716cf0f9,
        0x00017a9c3f336475
    )
    let b = FieldElement(
        0x0006c3d7704268ce,
        0x00018854dc7b9ce6,
        0x0005a3e71fbacd11,
        0x0007b12faf5be38a,
        0x000207fc6cc34079
    )
    let two = FieldElement(2, 0, 0, 0, 0)
    
    func testValidEncodings() {
        let vectors: [(input: [UInt8], expected: FieldElement)] = [
            (
                "0000000000000000000000000000000000000000000000000000000000000000",
                .zero
            ),
            (
                "0100000000000000000000000000000000000000000000000000000000000000",
                .one
            ),
            (
                "0200000000000000000000000000000000000000000000000000000000000000",
                two
            ),
            (
                "04fedf98a7fa0a688492bd590807a7039ed1f6f2e1d9e2a4a4514736f3c3a917",
                a
            ),
            (
                "ce684270d7c336e7dce3a6424c44b3eec7f96815c7b75e5f629f0734ccc67f20",
                b
            ),
            (
                "ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
                .zero - .one
            )
        ]
        
        for (input, expected) in vectors {
            XCTAssertEqual(FieldElement(from: input), expected)
            XCTAssertEqual(FieldElement(from: input)?.encoded(), input)
            XCTAssertEqual(expected.encoded(), input)
        }
    }
    
    func testCanonicalization() {
        let one = FieldElement(canonicalizing:
            "eeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f" as [UInt8])
        XCTAssertEqual(one, .one)
    }
    
    func testHighBitIgnored() {
        let highBitSet: [UInt8] = "71bfa98f5bea790ff183d924e6655cea08d0aafb617f46d23a17a657f0a9b8b2"
        var highBitCleared = highBitSet
        highBitCleared[31] &= 0b0111_1111
        XCTAssertEqual(FieldElement(canonicalizing: highBitSet), FieldElement(from: highBitCleared))
    }
    
    func testIsNegative() {
        XCTAssertFalse(Bool(FieldElement.zero.isNegative()))
        XCTAssertTrue(Bool(FieldElement.one.isNegative()))
        XCTAssertFalse(Bool(two.isNegative()))
        XCTAssertFalse(Bool(a.isNegative()))
        XCTAssertTrue(Bool((-a).isNegative()))
    }
    
    func testIsZero() {
        XCTAssertTrue(Bool(FieldElement.zero.isZero()))
        XCTAssertFalse(Bool(FieldElement.one.isZero()))
        XCTAssertFalse(Bool(a.isZero()))
    }
    
    func testEqualTo() {
        XCTAssertTrue(Bool((a == a) as CTBool))
        XCTAssertFalse(Bool((a == b) as CTBool))
    }
    
    func testAddition() {
        let expected = FieldElement(from:
            "d26622097fbe414f6176649c544b5af265cb5f08a991410407f14e6abf8a2938" as [UInt8])!
        XCTAssertEqual(a + b, expected)
        XCTAssertEqual(b + a, expected)
        XCTAssertEqual(a + .zero, a)
    }
    
    func testSubtraction() {
        let expected = FieldElement(from:
            "23959d28d036d480a7ae1617bcc2f314d6d78ddd1a22844542b23f0227fd2977" as [UInt8])!
        XCTAssertEqual(a - b, expected)
        XCTAssertEqual(b - a, -expected)
        XCTAssertEqual(a - .zero, a)
        XCTAssertEqual(.zero - a, -a)
    }
    
    func testNegation() {
        let expected = FieldElement(from:
            "e90120675805f5977b6d42a6f7f858fc612e090d1e261d5b5baeb8c90c3c5668" as [UInt8])!
        XCTAssertEqual(-a, expected)
        XCTAssertEqual(-(-a), a)
    }
    
    func testAbs() {
        XCTAssertEqual(abs(a), a)
        XCTAssertEqual(abs(-a), a)
    }
    
    func testMultiplication() {
        let expected = FieldElement(from:
            "d3134f66f526b27839a01ec5d9949dcd01fe6dc2edc5471e5bc8bf2faacfc64d" as [UInt8])!
        XCTAssertEqual(a * b, expected)
        XCTAssertEqual(b * a, expected)
        XCTAssertEqual(a * .zero, .zero)
        XCTAssertEqual(a * .one, a)
        XCTAssertEqual(a * two, a + a)
    }
    
    func testSquaring() {
        let expected = FieldElement(from:
            "7597249ee606feab2404566807912d5d0b0f3f1cb26ef2e2639c12ba730be362" as [UInt8])!
        XCTAssertEqual(a.squared(), expected)
        XCTAssertEqual(a.squared(), a * a)
        XCTAssertEqual(FieldElement.zero.squared(), .zero)
        XCTAssertEqual(FieldElement.one.squared(), .one)
        XCTAssertEqual(two.squared(), two + two)
    }
    
    func testPowTwo252MinusThree() {
        let expected = FieldElement(from:
            "6a4f24891f576036d0be123c8ff5b159e0f0b81b20d2b51f1521f9e3e1612155" as [UInt8])!
        XCTAssertEqual(a.powTwo252MinusThree(), expected)
    }
    
    func testInversion() {
        let expected = FieldElement(from:
            "961bcd8d4d5ea23ae9363793db7b4d70b80dc055d04c1d7b9071d8e9b618e630" as [UInt8])!
        XCTAssertEqual(a.inverted(), expected)
        XCTAssertEqual(a.inverted().inverted(), a)
    }
    
    func testSquareRootOver() {
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
        Bool((lhs == rhs) as CTBool)
    }
}

extension FieldElement: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = UInt64
    
    public init(integerLiteral value: IntegerLiteralType) {
        self = FieldElement(value, 0, 0, 0, 0)
    }
}

fileprivate extension Int {
    func squareRoot(over denominator: FieldElement) -> (result: FieldElement, wasSquare: CTBool) {
        FieldElement(UInt64(self), 0, 0, 0, 0).squareRoot(over: denominator)
    }
}
