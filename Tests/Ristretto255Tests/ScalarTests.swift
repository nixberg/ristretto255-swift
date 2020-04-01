import XCTest
@testable import Ristretto255

final class ScalarTests: XCTestCase {
    private let a = Scalar(
        0x0005236c07b3be89,
        0x0001bc3d2a67c0c4,
        0x000a4aa782aae3ee,
        0x0006b3f6e4fec4c4,
        0x00000532da9fab8c
    )
    
    private let b = Scalar(
        0x000d3fae55421564,
        0x000c2df24f65a4bc,
        0x0005b5587d69fb0b,
        0x00094c091b013b3b,
        0x00000acd25605473
    )
    
    private let x = Scalar(
        0x000fffffffffffff,
        0x000fffffffffffff,
        0x000fffffffffffff,
        0x000fffffffffffff,
        0x00001fffffffffff
    )
    
    func testRoundtrip() {
        XCTAssertEqual(Scalar(from: a.encoded()), a)
    }
    
    func testRoundtripRandom() {
        for _ in 0..<32 {
            let scalar = Scalar.random()
            XCTAssertEqual(Scalar(from: scalar.encoded()), scalar)
        }
    }
    
    func testFromUniform() {
        let encoded = [UInt8](repeating: 255, count: 64)
        let expected = Scalar(
            0x000611e3449c0f00,
            0x000a768859347a40,
            0x0007f5be65d00e1b,
            0x0009a3dceec73d21,
            0x00000399411b7c30
        )
        XCTAssertEqual(Scalar(fromUniformBytes: encoded), expected)
    }
    
    func testAddition() {
        XCTAssertEqual(a + b, .zero)
    }
    
    func testSubtraction() {
        let expected = Scalar(
            0x000a46d80f677d12,
            0x0003787a54cf8188,
            0x0004954f0555c7dc,
            0x000d67edc9fd8989,
            0x00000a65b53f5718
        )
        XCTAssertEqual(a - b, expected)
        
        for _ in 0..<32 {
            let scalar = Scalar.random()
            XCTAssertEqual(scalar - scalar, .zero)
        }
    }
    
    func testMultiplication() {
        let y = Scalar(
            0x000b75071e1458fa,
            0x000bf9d75e1ecdac,
            0x000433d2baf0672b,
            0x0005fffcc11fad13,
            0x00000d96018bb825
        )
        let xx = Scalar(
            0x0001668020217559,
            0x000531640ffd0ec0,
            0x00085fd6f9f38a31,
            0x000c268f73bb1cf4,
            0x000006ce65046df0
        )
        let xy = Scalar(
            0x000ee6d76ba7632d,
            0x000ed50d71d84e02,
            0x00000000001ba634,
            0x0000000000000000,
            0x0000000000000000
        )
        XCTAssertEqual(x * x, xx)
        XCTAssertEqual(x * y, xy)
    }
}

extension Scalar: Equatable {
    public static func == (lhs: Scalar, rhs: Scalar) -> Bool {
        lhs.encoded() == rhs.encoded()
    }
}
