import Subtle
import Foundation

fileprivate let mask52: UInt64 = (1 << 52) - 1

fileprivate let order = Scalar(
    0x0002631a5cf5d3ed,
    0x000dea2f79cd6581,
    0x000000000014def9,
    0x0000000000000000,
    0x0000100000000000
)

fileprivate let montgomeryRadix = Scalar(
    0x000f48bd6721e6ed,
    0x0003bab5ac67e45a,
    0x000fffffeb35e51b,
    0x000fffffffffffff,
    0x00000fffffffffff
)

fileprivate let montgomeryRadixSquared = Scalar(
    0x0009d265e952d13b,
    0x000d63c715bea69f,
    0x0005be65cb687604,
    0x0003dceec73d217f,
    0x000009411b7c309a
)

public struct Scalar {
    private let a: UInt64
    private let b: UInt64
    private let c: UInt64
    private let d: UInt64
    private let e: UInt64
    
    static let zero = Self(0, 0, 0, 0, 0)
    
    init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64, _ e: UInt64) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
    }
    
    public init?<Input>(from input: Input) where Input: DataProtocol {
        precondition(input.count == 32)
        
        let scalar = SIMD4<UInt64>(fromLittleEndianBytes: input)
        
        let order = SIMD4<UInt64>(
            0x5812631a5cf5d3ed,
            0x14def9dea2f79cd6,
            0x0000000000000000,
            0x1000000000000000
        )
        
        guard scalar < order else {
            return nil
        }
        
        a = (                    (scalar[0] <<  0)) & mask52
        b = ((scalar[0] >> 52) | (scalar[1] << 12)) & mask52
        c = ((scalar[1] >> 40) | (scalar[2] << 24)) & mask52
        d = ((scalar[2] >> 28) | (scalar[3] << 36)) & mask52
        e = ((scalar[3] >> 16)                    )
    }
    
    public init<Input>(fromUniformBytes input: Input) where Input: DataProtocol {
        precondition(input.count == 64)
        
        let x = SIMD4<UInt64>(fromLittleEndianBytes: input.prefix(32))
        let y = SIMD4<UInt64>(fromLittleEndianBytes: input.suffix(32))
        
        let low = Scalar(
            (               (x[0] <<  0)) & mask52,
            ((x[0] >> 52) | (x[1] << 12)) & mask52,
            ((x[1] >> 40) | (x[2] << 24)) & mask52,
            ((x[2] >> 28) | (x[3] << 32)) & mask52,
            ((x[3] >> 16) | (y[0] << 48)) & mask52
        ).montgomeryMultiplied(with: montgomeryRadix)
        
        let high = Scalar(
            ((y[0] >>  4)               ) & mask52,
            ((y[0] >> 56) | (y[1] <<  8)) & mask52,
            ((y[1] >> 44) | (y[2] << 20)) & mask52,
            ((y[2] >> 32) | (y[3] << 32)) & mask52,
            ((y[3] >> 20)               )
        ).montgomeryMultiplied(with: montgomeryRadixSquared)
        
        self = low + high
    }
    
    public static func random(using generator: inout RandomNumberGenerator) -> Self {
        Self(fromUniformBytes: (0..<64).map { _ in generator.next() })
    }
    
    public static func random() -> Self {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return self.random(using: &generator)
    }
    
    public func encode<Output>(to output: inout Output) where Output: MutableDataProtocol {
        for n in stride(from: 0, to: 48, by: 8) {
            output.append(UInt8(truncatingIfNeeded: a &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: (a &>> 48) | (b &<< 4)))
        
        for n in stride(from: 4, to: 52, by: 8) {
            output.append(UInt8(truncatingIfNeeded: b &>> n))
        }
        
        for n in stride(from: 0, to: 48, by: 8) {
            output.append(UInt8(truncatingIfNeeded: c &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: (c &>> 48) | (d &<< 4)))
        
        for n in stride(from: 4, to: 52, by: 8) {
            output.append(UInt8(truncatingIfNeeded: d &>> n))
        }
        
        for n in stride(from: 0, to: 48, by: 8) {
            output.append(UInt8(truncatingIfNeeded: e &>> n))
        }
    }
    
    public func encoded() -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(32)
        self.encode(to: &output)
        return output
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        var carry: UInt64
        carry = lhs.a &+ rhs.a
        let a = carry & mask52
        carry = lhs.b &+ rhs.b &+ (carry >> 52)
        let b = carry & mask52
        carry = lhs.c &+ rhs.c &+ (carry >> 52)
        let c = carry & mask52
        carry = lhs.d &+ rhs.d &+ (carry >> 52)
        let d = carry & mask52
        carry = lhs.e &+ rhs.e &+ (carry >> 52)
        let e = carry & mask52
        
        return Self(a, b, c, d, e) - order
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        var borrow: UInt64
        borrow = lhs.a &- rhs.a
        var a = borrow & mask52
        borrow = lhs.b &- rhs.b &- (borrow >> 63)
        var b = borrow & mask52
        borrow = lhs.c &- rhs.c &- (borrow >> 63)
        var c = borrow & mask52
        borrow = lhs.d &- rhs.d &- (borrow >> 63)
        var d = borrow & mask52
        borrow = lhs.e &- rhs.e &- (borrow >> 63)
        var e = borrow & mask52
        
        let underflowMask = ((borrow >> 63) ^ 1) &- 1
        
        var carry: UInt64
        carry = a &+ (order.a & underflowMask)
        a = carry & mask52
        carry = b &+ (order.b & underflowMask) &+ (carry >> 52)
        b = carry & mask52
        carry = c &+ (order.c & underflowMask) &+ (carry >> 52)
        c = carry & mask52
        carry = d &+ (order.d & underflowMask) &+ (carry >> 52)
        d = carry & mask52
        carry = e &+ (order.e & underflowMask) &+ (carry >> 52)
        e = carry & mask52
        
        return Self(a, b, c, d, e)
    }
    
    public static func * (lhs: Self, rhs: Self) -> Self {
        lhs.montgomeryMultiplied(with: rhs).montgomeryMultiplied(with: montgomeryRadixSquared)
    }
    
    private func montgomeryMultiplied(with other: Self) -> Self {
        let w0 = a <*> other.a
        let w1 = a <*> other.b &+ b <*> other.a
        let w2 = a <*> other.c &+ b <*> other.b &+ c <*> other.a
        let w3 = a <*> other.d &+ b <*> other.c &+ c <*> other.b &+ d <*> other.a
        let w4 = a <*> other.e &+ b <*> other.d &+ c <*> other.c &+ d <*> other.b &+ e <*> other.a
        let w5 =                  b <*> other.e &+ c <*> other.d &+ d <*> other.c &+ e <*> other.b
        let w6 =                                   c <*> other.e &+ d <*> other.d &+ e <*> other.c
        let w7 =                                                    d <*> other.e &+ e <*> other.d
        let w8 =                                                                     e <*> other.e
        
        @inline(__always)
        func one(_ sum: UInt128) -> (UInt128, UInt64) {
            let p = (sum.low &* 0x51da312547e1b) & mask52
            return ((sum &+ p <*> order.a) >> 52, p)
        }
        
        @inline(__always)
        func two(_ sum: UInt128) -> (UInt128, UInt64) {
            (sum >> 52, sum.low & mask52)
        }
        
        var carry: UInt128
        let n0, n1, n2, n3, n4: UInt64
        
        (carry, n0) = one(         w0)
        (carry, n1) = one(carry &+ w1 &+ n0 <*> order.b)
        (carry, n2) = one(carry &+ w2 &+ n0 <*> order.c &+ n1 <*> order.b)
        (carry, n3) = one(carry &+ w3                   &+ n1 <*> order.c &+ n2 <*> order.b)
        (carry, n4) = one(carry &+ w4 &+ n0 <*> order.e                   &+ n2 <*> order.c &+ n3 <*> order.b)
        
        let r0, r1, r2, r3, r4: UInt64
        
        (carry, r0) = two(carry &+ w5 &+ n1 <*> order.e                   &+ n3 <*> order.c &+ n4 <*> order.b)
        (carry, r1) = two(carry &+ w6                   &+ n2 <*> order.e                   &+ n4 <*> order.c)
        (carry, r2) = two(carry &+ w7                                     &+ n3 <*> order.e                  )
        (carry, r3) = two(carry &+ w8                                                       &+ n4 <*> order.e)
                r4  = carry.low
        
        return Self(r0, r1, r2, r3, r4) - order
    }
}

extension UInt64 {
    init<Input>(fromLittleEndianBytes input: Input) where Input: DataProtocol {
        assert(input.count == MemoryLayout<Self>.size)
        self = input.reduce(0) { ($0 << 8) | Self($1) }.byteSwapped
    }
}

extension SIMD4 where Scalar == UInt64 {
    fileprivate init<Input>(fromLittleEndianBytes input: Input) where Input: DataProtocol {
        let scalarSize = MemoryLayout<Scalar>.size
        assert(input.count == Self.scalarCount * scalarSize)
        
        var input = input[...]
        let x = Scalar(fromLittleEndianBytes: input.prefix(scalarSize))
        input = input.dropFirst(scalarSize)
        let y = Scalar(fromLittleEndianBytes: input.prefix(scalarSize))
        input = input.dropFirst(scalarSize)
        let z = Scalar(fromLittleEndianBytes: input.prefix(scalarSize))
        input = input.dropFirst(scalarSize)
        let w = Scalar(fromLittleEndianBytes: input.prefix(scalarSize))
        
        self = Self(x, y, z, w)
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        var result: Choice = .false
        var wasSet: Choice = .false
        
        for i in lhs.indices.reversed() {
            result.replace(with: lhs[i] < rhs[i], if: !wasSet)
            wasSet ||= !(lhs[i] == rhs[i])
        }
        
        return Bool(result)
    }
}

typealias SignedRadix16 = SIMD64<Int8>

extension SignedRadix16 {
    init(from scalar: Ristretto255.Scalar) {
        self.init()
        
        for (i, byte) in zip(stride(from: 0, to: 64, by: 2), scalar.encoded()) {
            self[i + 0] = Int8(byte & 0xf)
            self[i + 1] = Int8((byte >> 4) & 0xf)
        }
        
        for i in 0..<63 {
            let carry = (self[i] &+ 8) >> 4
            self[i + 0] &-= carry << 4
            self[i + 1] &+= carry
        }
    }
}
