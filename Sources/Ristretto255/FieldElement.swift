import Foundation

fileprivate let mask: UInt64 = (1 << 51) - 1

let squareRootMinusOne = FieldElement(
    0x00061b274a0ea0b0,
    0x0000d5a5fc8f189d,
    0x0007ef5e9cbd0c60,
    0x00078595a6804c9e,
    0x0002b8324804fc1d
)

struct FieldElement {
    fileprivate let a: UInt64
    fileprivate let b: UInt64
    fileprivate let c: UInt64
    fileprivate let d: UInt64
    fileprivate let e: UInt64
    
    static let zero = FieldElement(0)
    
    static let one = FieldElement(1)
    
    init(_ a: UInt64, _ b: UInt64 = 0, _ c: UInt64 = 0, _ d: UInt64 = 0, _ e: UInt64 = 0) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
    }
    
    init<D>(from data: D) where D: DataProtocol {
        assert(data.count == 32)
        a = (UInt64(fromBytes: data.suffix(32 -  0)) &>>  0) & mask
        b = (UInt64(fromBytes: data.suffix(32 -  6)) &>>  3) & mask
        c = (UInt64(fromBytes: data.suffix(32 - 12)) &>>  6) & mask
        d = (UInt64(fromBytes: data.suffix(32 - 19)) &>>  1) & mask
        e = (UInt64(fromBytes: data.suffix(32 - 24)) &>> 12) & mask
    }
    
    private func encodedFromReduced() -> [UInt8] {
        [
            a &>>  0,
            a &>>  8,
            a &>> 16,
            a &>> 24,
            a &>> 32,
            a &>> 40,
            a &>> 48 | b &<< 3,
            
            b &>>  5,
            b &>> 13,
            b &>> 21,
            b &>> 29,
            b &>> 37,
            b &>> 45 | c &<< 6,
            
            c &>>  2,
            c &>> 10,
            c &>> 18,
            c &>> 26,
            c &>> 34,
            c &>> 42,
            c &>> 50 | d &<< 1,
            
            d &>>  7,
            d &>> 15,
            d &>> 23,
            d &>> 31,
            d &>> 39,
            d &>> 47 | e &<< 4,
            
            e &>>  4,
            e &>> 12,
            e &>> 20,
            e &>> 28,
            e &>> 36,
            e &>> 44
        ].map {
            UInt8(truncatingIfNeeded: $0)
        }
    }
    
    public func encoded() -> [UInt8] {
        self.reduced().encodedFromReduced()
    }
    
    func isPositive() -> CTBool {
        CTBool((self.encoded()[0] & 0x01) ^ 0x01)
    }
    
    func isNegative() -> CTBool {
        !self.isPositive()
    }
    
    func isZero() -> CTBool {
        self.encoded().reduce(0, |) == 0x00
    }
    
    static func == (lhs: FieldElement, rhs: FieldElement) -> CTBool {
        lhs.encoded() == rhs.encoded()
    }
    
    static func + (lhs: FieldElement, rhs: FieldElement) -> FieldElement {
        FieldElement(
            lhs.a &+ rhs.a,
            lhs.b &+ rhs.b,
            lhs.c &+ rhs.c,
            lhs.d &+ rhs.d,
            lhs.e &+ rhs.e
        )
    }
    
    prefix static func - (x: FieldElement) -> FieldElement {
        FieldElement(
            0x007ffffffffffed0 &- x.a,
            0x007ffffffffffff0 &- x.b,
            0x007ffffffffffff0 &- x.c,
            0x007ffffffffffff0 &- x.d,
            0x007ffffffffffff0 &- x.e
        ).weaklyReduced()
    }
    
    static func - (lhs: FieldElement, rhs: FieldElement) -> FieldElement {
        FieldElement(
            (lhs.a &+ 0x007ffffffffffed0) &- rhs.a,
            (lhs.b &+ 0x007ffffffffffff0) &- rhs.b,
            (lhs.c &+ 0x007ffffffffffff0) &- rhs.c,
            (lhs.d &+ 0x007ffffffffffff0) &- rhs.d,
            (lhs.e &+ 0x007ffffffffffff0) &- rhs.e
        ).weaklyReduced()
    }
    
    static func * (lhs: FieldElement, rhs: FieldElement) -> FieldElement {
        let x = lhs
        let y = rhs
        let m = (
            b: 19 &* y.b,
            c: 19 &* y.c,
            d: 19 &* y.d,
            e: 19 &* y.e
        )
        
        let c0 = x.a <*> y.a &+ x.e <*> m.b &+ x.d <*> m.c &+ x.c <*> m.d &+ x.b <*> m.e
        var c1 = x.b <*> y.a &+ x.a <*> y.b &+ x.e <*> m.c &+ x.d <*> m.d &+ x.c <*> m.e
        var c2 = x.c <*> y.a &+ x.b <*> y.b &+ x.a <*> y.c &+ x.e <*> m.d &+ x.d <*> m.e
        var c3 = x.d <*> y.a &+ x.c <*> y.b &+ x.b <*> y.c &+ x.a <*> y.d &+ x.e <*> m.e
        var c4 = x.e <*> y.a &+ x.d <*> y.b &+ x.c <*> y.c &+ x.b <*> y.d &+ x.a <*> y.e
        
        c1 &+>= (c0 &>> 51).low
        c2 &+>= (c1 &>> 51).low
        c3 &+>= (c2 &>> 51).low
        c4 &+>= (c3 &>> 51).low
        
        let a = (c0.low & mask) &+ 19 &* (c4 &>> 51).low
        let b = (c1.low & mask) &+ a &>> 51
        
        return FieldElement(
            a & mask,
            b,
            c2.low & mask,
            c3.low & mask,
            c4.low & mask
        )
    }
    
    func squared() -> FieldElement {
        let m = (
            d: 19 &* d,
            e: 19 &* e
        )
        
        let c0 = a <*>   a &+ (b <*> m.e &+ c <*> m.d).doubled()
        let c1 = d <*> m.d &+ (a <*>   b &+ c <*> m.e).doubled() &+> (c0 &>> 51).low
        let c2 = b <*>   b &+ (a <*>   c &+ e <*> m.d).doubled() &+> (c1 &>> 51).low
        let c3 = e <*> m.e &+ (a <*>   d &+ b <*>   c).doubled() &+> (c2 &>> 51).low
        let c4 = c <*>   c &+ (a <*>   e &+ b <*>   d).doubled() &+> (c3 &>> 51).low
        
        let a = (c0.low & mask) &+ 19 &* (c4 &>> 51).low
        let b = (c1.low & mask) &+ a &>> 51
        
        return FieldElement(
            a & mask,
            b,
            c2.low & mask,
            c3.low & mask,
            c4.low & mask
        )
    }
    
    func squaredTimesTwo() -> FieldElement {
        let squared = self.squared()
        return FieldElement(
            2 &* squared.a,
            2 &* squared.b,
            2 &* squared.c,
            2 &* squared.d,
            2 &* squared.e
        )
    }
    
    private func pow2(_ k: Int) -> FieldElement {
        (0..<k).reduce(self, { (fe, _) in fe.squared() })
    }
    
    private func pow2250MinusOne() -> (FieldElement, FieldElement) {
        let t0  = self.squared()
        let t1  = t0.squared().squared()
        let t2  = self * t1
        let t3  = t0 * t2
        let t4  = t3.squared()
        let t5  = t2 * t4
        let t6  = t5.pow2(5)
        let t7  = t6 * t5
        let t8  = t7.pow2(10)
        let t9  = t8 * t7
        let t10 = t9.pow2(20)
        let t11 = t10 * t9
        let t12 = t11.pow2(10)
        let t13 = t12 * t7
        let t14 = t13.pow2(50)
        let t15 = t14 * t13
        let t16 = t15.pow2(100)
        let t17 = t16 * t15
        let t18 = t17.pow2(50)
        let t19 = t18 * t13
        
        return (t19, t3)
    }
    
    private func pow2250MinusOne() -> FieldElement {
        let (result, _) = self.pow2250MinusOne()
        return result
    }
    
    func pow2252MinusThree() -> FieldElement {
        self * self.pow2250MinusOne().pow2(2)
    }
    
    func inverted() -> FieldElement {
        let (t19, t3) = self.pow2250MinusOne()
        let t20 = t19.pow2(5)
        return t20 * t3
    }
    
    func squareRoot(over v: FieldElement) -> (CTBool, FieldElement) {
        let v3 = v.squared() * v
        let v7 = v3.squared() * v
        
        var r = (self * v3) * (self * v7).pow2252MinusThree()
        let check = v * r.squared()
        
        let minusSelf = -self
        let isSignCorrect        = (check ==  self)
        let isSignFlipped        = (check == minusSelf)
        let isInverseSignFlipped = (check == minusSelf * squareRootMinusOne)
        
        let rPrime = squareRootMinusOne * r
        r = (isSignFlipped || isInverseSignFlipped).then(rPrime, else: r)
        
        return (isSignCorrect || isSignFlipped, abs(r))
    }
    
    func inverseSquareRoot() -> (CTBool, FieldElement) {
        FieldElement.one.squareRoot(over: self)
    }
    
    private func weaklyReduced() -> FieldElement {
        FieldElement(
            (a & mask) &+ (e &>> 51) &* 19,
            (b & mask) &+ (a &>> 51),
            (c & mask) &+ (b &>> 51),
            (d & mask) &+ (c &>> 51),
            (e & mask) &+ (d &>> 51)
        )
    }
    
    private func stronglyReduced() -> FieldElement {
        let q = [a, b, c, d, e].reduce(19, { (q, limb) in
            (q &+ limb) &>> 51
        })
        
        let a = self.a &+ 19 &* q
        let b = self.b &+ (a &>> 51)
        let c = self.c &+ (b &>> 51)
        let d = self.d &+ (c &>> 51)
        let e = self.e &+ (d &>> 51)
        
        return FieldElement(
            a & mask,
            b & mask,
            c & mask,
            d & mask,
            e & mask
        )
    }
    
    @inline(__always)
    private func reduced() -> FieldElement {
        self.weaklyReduced().stronglyReduced()
    }
}

func abs(_ x: FieldElement) -> FieldElement {
    x.isPositive().then(x, else: -x)
}

fileprivate extension UInt64 {
    init<D>(fromBytes data: D) where D: DataProtocol {
        assert(data.count >= 8)
        self = data.prefix(8).enumerated().map { UInt64($0.1) &<< ($0.0 &* 8) }.reduce(0, |)
    }
}

extension CTBool {
    func then(_ `true`: FieldElement, else `false`: FieldElement) -> FieldElement {
        let mask = UInt64(rawValue) &- 1
        let antimask = ~mask
        return FieldElement(
            (`true`.a & antimask) | (`false`.a & mask),
            (`true`.b & antimask) | (`false`.b & mask),
            (`true`.c & antimask) | (`false`.c & mask),
            (`true`.d & antimask) | (`false`.d & mask),
            (`true`.e & antimask) | (`false`.e & mask)
        )
    }
}
