import Foundation

fileprivate let mask: UInt64 = (1 << 52) - 1

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
    
    public init() {
        a = 0
        b = 0
        c = 0
        d = 0
        e = 0
    }
    
    init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64, _ e: UInt64) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
    }
    
    public init?<D>(from data: D) where D: DataProtocol {
        precondition(data.count == 32)
        
        var words = [UInt64](repeating: 0, count: 4)
        for (i, byte) in data.enumerated() {
            words[i / 8] |= UInt64(byte) &<< (8 &* (i % 8))
        }
        
        guard words.isMinimal() else {
            return nil
        }
        
        a = (                  words[0] &<<  0) & mask
        b = (words[0] &>> 52 | words[1] &<< 12) & mask
        c = (words[1] &>> 40 | words[2] &<< 24) & mask
        d = (words[2] &>> 28 | words[3] &<< 36) & mask
        e = (words[3] &>> 16                  ) & mask >> 4
    }
    
    public init<D>(fromUniformBytes data: D) where D: DataProtocol {
        precondition(data.count == 64)
        
        var words = [UInt64](repeating: 0, count: 8)
        for (i, byte) in data.enumerated() {
            words[i / 8] |= UInt64(byte) &<< (8 * (i % 8))
        }
        
        let low = Scalar(
            (                  words[0] &<<  0) & mask,
            (words[0] &>> 52 | words[1] &<< 12) & mask,
            (words[1] &>> 40 | words[2] &<< 24) & mask,
            (words[2] &>> 28 | words[3] &<< 32) & mask,
            (words[3] &>> 16 | words[4] &<< 48) & mask
        )
        
        let high = Scalar(
            (words[4] &>>  4                  ) & mask,
            (words[4] &>> 56 | words[5] &<<  8) & mask,
            (words[5] &>> 44 | words[6] &<< 20) & mask,
            (words[6] &>> 32 | words[7] &<< 32) & mask,
            (words[7] &>> 20                  )
        )
        
        self = Scalar.reduce(Scalar.multiply(low, montgomeryRadix)) +
               Scalar.reduce(Scalar.multiply(high, montgomeryRadixSquared))
    }
    
    public static func random() -> Scalar {
        var rng = SystemRandomNumberGenerator()
        return Scalar(fromUniformBytes: (0..<64).map { _ in rng.next() })
    }
    
    public func encode<M>(to data: inout M) where M: MutableDataProtocol {
        data.append(contentsOf: [
            a &>>  0,
            a &>>  8,
            a &>> 16,
            a &>> 24,
            a &>> 32,
            a &>> 40,
            a &>> 48 | b &<< 4,
            
            b &>>  4,
            b &>> 12,
            b &>> 20,
            b &>> 28,
            b &>> 36,
            b &>> 44,
            
            c &>>  0,
            c &>>  8,
            c &>> 16,
            c &>> 24,
            c &>> 32,
            c &>> 40,
            c &>> 48 | d &<< 4,
            
            d &>>  4,
            d &>> 12,
            d &>> 20,
            d &>> 28,
            d &>> 36,
            d &>> 44,
            
            e &>>  0,
            e &>>  8,
            e &>> 16,
            e &>> 24,
            e &>> 32,
            e &>> 40
        ].map {
            UInt8(truncatingIfNeeded: $0)
        })
    }
    
    public func encoded() -> [UInt8] {
        var data = [UInt8]()
        self.encode(to: &data)
        return data
    }
    
    public static func + (lhs: Scalar, rhs: Scalar) -> Scalar {
        var carry: UInt64
        carry = lhs.a &+ rhs.a
        let a = carry & mask
        carry = lhs.b &+ rhs.b &+ (carry &>> 52)
        let b = carry & mask
        carry = lhs.c &+ rhs.c &+ (carry &>> 52)
        let c = carry & mask
        carry = lhs.d &+ rhs.d &+ (carry &>> 52)
        let d = carry & mask
        carry = lhs.e &+ rhs.e &+ (carry &>> 52)
        let e = carry & mask
        
        return Scalar(a, b, c, d, e) - order
    }
    
    public static func - (lhs: Scalar, rhs: Scalar) -> Scalar {
        var borrow: UInt64
        borrow = lhs.a &- rhs.a
        var a = borrow & mask
        borrow = lhs.b &- rhs.b &- (borrow &>> 63)
        var b = borrow & mask
        borrow = lhs.c &- rhs.c &- (borrow &>> 63)
        var c = borrow & mask
        borrow = lhs.d &- rhs.d &- (borrow &>> 63)
        var d = borrow & mask
        borrow = lhs.e &- rhs.e &- (borrow &>> 63)
        var e = borrow & mask
        
        let underflowMask = ((borrow &>> 63) ^ 1) &- 1
        
        var carry: UInt64
        carry = a &+ (order.a & underflowMask)
        a = carry & mask
        carry = b &+ (order.b & underflowMask) &+ (carry &>> 52)
        b = carry & mask
        carry = c &+ (order.c & underflowMask) &+ (carry &>> 52)
        c = carry & mask
        carry = d &+ (order.d & underflowMask) &+ (carry &>> 52)
        d = carry & mask
        carry = e &+ (order.e & underflowMask) &+ (carry &>> 52)
        e = carry & mask
        
        return Scalar(a, b, c, d, e)
    }
    
    public static func * (lhs: Scalar, rhs: Scalar) -> Scalar {
        reduce(multiply(reduce(multiply(lhs, rhs)), montgomeryRadixSquared))
    }
    
    private static func multiply(_ lhs: Scalar, _ rhs: Scalar) -> [UInt128] {
        [
            lhs.a <*> rhs.a,
            lhs.a <*> rhs.b &+ lhs.b <*> rhs.a,
            lhs.a <*> rhs.c &+ lhs.b <*> rhs.b &+ lhs.c <*> rhs.a,
            lhs.a <*> rhs.d &+ lhs.b <*> rhs.c &+ lhs.c <*> rhs.b &+ lhs.d <*> rhs.a,
            lhs.a <*> rhs.e &+ lhs.b <*> rhs.d &+ lhs.c <*> rhs.c &+ lhs.d <*> rhs.b &+ lhs.e <*> rhs.a,
                               lhs.b <*> rhs.e &+ lhs.c <*> rhs.d &+ lhs.d <*> rhs.c &+ lhs.e <*> rhs.b,
                                                  lhs.c <*> rhs.e &+ lhs.d <*> rhs.d &+ lhs.e <*> rhs.c,
                                                                     lhs.d <*> rhs.e &+ lhs.e <*> rhs.d,
                                                                                        lhs.e <*> rhs.e
        ]
    }
    
    private static func reduce(_ limbs: [UInt128]) -> Scalar {
        @inline(__always)
        func one(_ sum: UInt128) -> (UInt128, UInt64) {
            let p = (sum.low &* 0x51da312547e1b) & mask
            return ((sum &+ p <*> order.a) &>> 52, p)
        }
        
        @inline(__always)
        func two(_ sum: UInt128) -> (UInt128, UInt64) {
            let w = sum.low & mask
            return (sum &>> 52, w)
        }
        
        var carry: UInt128
        let n0, n1, n2, n3, n4: UInt64
        
        (carry, n0) = one(         limbs[0])
        (carry, n1) = one(carry &+ limbs[1] &+ n0 <*> order.b)
        (carry, n2) = one(carry &+ limbs[2] &+ n0 <*> order.c &+ n1 <*> order.b)
        (carry, n3) = one(carry &+ limbs[3]                   &+ n1 <*> order.c &+ n2 <*> order.b)
        (carry, n4) = one(carry &+ limbs[4] &+ n0 <*> order.e                   &+ n2 <*> order.c &+ n3 <*> order.b)
        
        let r0, r1, r2, r3, r4: UInt64
        
        (carry, r0) = two(carry &+ limbs[5] &+ n1 <*> order.e                   &+ n3 <*> order.c &+ n4 <*> order.b)
        (carry, r1) = two(carry &+ limbs[6]                   &+ n2 <*> order.e                   &+ n4 <*> order.c)
        (carry, r2) = two(carry &+ limbs[7]                                     &+ n3 <*> order.e                  )
        (carry, r3) = two(carry &+ limbs[8]                                                       &+ n4 <*> order.e)
                r4  = carry.low
        
        return Scalar(r0, r1, r2, r3, r4) - order
    }
    
    func radix16() -> [Int8] {
        var output = [Int8](repeating: 0, count: 64)
        
        for (i, byte) in self.encoded().enumerated() {
            output[2 &* i     ] = Int8(byte & 15)
            output[2 &* i &+ 1] = Int8((byte &>> 4) & 15)
        }
        
        for i in 0..<63 {
            let carry = (output[i] &+ 8) &>> 4
            output[i     ] = output[i     ] &- (carry &<< 4)
            output[i &+ 1] = output[i &+ 1] &+ carry
        }
        
        return output
    }
}

fileprivate extension Array where Element == UInt64 {
    func isMinimal() -> Bool {
        let order: [UInt64] = [
            0x5812631a5cf5d3ed,
            0x14def9dea2f79cd6,
            0x0000000000000000,
            0x1000000000000000
        ]
        
        for (i, w) in self.enumerated().reversed() {
            if w < order[i] {
                return true
            } else if w > order[i] {
                return false
            }
        }
        
        return false
    }
}
