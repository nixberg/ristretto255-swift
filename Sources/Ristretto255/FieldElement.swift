import ConstantTime
import Foundation

fileprivate let mask51: UInt64 = (1 << 51) - 1

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
    
    static let zero = Self(0, 0, 0, 0, 0)
    
    static let one = Self(1, 0, 0, 0, 0)
    
    func assertBounds() {
        let upperBound = 1 << 52
        assert(a < upperBound)
        assert(b < upperBound)
        assert(c < upperBound)
        assert(d < upperBound)
        assert(e < upperBound)
    }
    
    init(_ a: UInt64, _ b: UInt64, _ c: UInt64, _ d: UInt64, _ e: UInt64) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
    }
    
    private init<Input>(unchecked input: Input) where Input: DataProtocol {
        precondition(input.count == 32)
        
        var input = input[...]
        let a = (UInt64(fromLittleEndianBytes: input.prefix(8)) &>>  0) & mask51
        input = input.dropFirst(6)
        let b = (UInt64(fromLittleEndianBytes: input.prefix(8)) &>>  3) & mask51
        input = input.dropFirst(6)
        let c = (UInt64(fromLittleEndianBytes: input.prefix(8)) &>>  6) & mask51
        input = input.dropFirst(7)
        let d = (UInt64(fromLittleEndianBytes: input.prefix(8)) &>>  1) & mask51
        input = input.dropFirst(5)
        let e = (UInt64(fromLittleEndianBytes: input.prefix(8)) &>> 12) & mask51
        
        self.init(a, b, c, d, e)
    }
    
    init?<Input>(from input: Input) where Input: DataProtocol {
        self.init(unchecked: input)
        guard zip(self.encoded(), input).map(^).reduce(0, |) == 0 else {
            return nil
        }
    }
    
    init<Input>(canonicalizing input: Input) where Input: DataProtocol {
        self = Self(unchecked: input).canonicalized()
    }
    
    public func encode<Output>(to output: inout Output) where Output: MutableDataProtocol {
        let canonical = self.canonicalized()
        
        for n in stride(from: 0, to: 48, by: 8) {
            output.append(UInt8(truncatingIfNeeded: canonical.a &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: canonical.a &>> 48 | canonical.b &<< 3))
        
        for n in stride(from: 5, to: 45, by: 8) {
            output.append(UInt8(truncatingIfNeeded: canonical.b &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: canonical.b &>> 45 | canonical.c &<< 6))
        
        for n in stride(from: 2, to: 50, by: 8) {
            output.append(UInt8(truncatingIfNeeded: canonical.c &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: canonical.c &>> 50 | canonical.d &<< 1))
        
        for n in stride(from: 7, to: 47, by: 8) {
            output.append(UInt8(truncatingIfNeeded: canonical.d &>> n))
        }
        output.append(UInt8(truncatingIfNeeded: canonical.d &>> 47 | canonical.e &<< 4))
        
        for n in stride(from: 4, to: 52, by: 8) {
            output.append(UInt8(truncatingIfNeeded: canonical.e &>> n))
        }
        
        assert(canonical.e &>> 51 == 0)
    }
    
    public func encoded() -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(32)
        self.encode(to: &output)
        return output
    }
    
    var isNegative: Choice {
        Choice(unsafeRawValue: UInt8(truncatingIfNeeded: self.canonicalized().a) & 0x01)
    }
    
    var isZero: Choice {
        let canonical = self.canonicalized()
        return canonical.a == 0
            && canonical.b == 0
            && canonical.c == 0
            && canonical.d == 0
            && canonical.e == 0
    }
    
    static func == (lhs: Self, rhs: Self) -> Choice {
        let lhs = lhs.canonicalized()
        let rhs = rhs.canonicalized()
        return lhs.a == rhs.a
            && lhs.b == rhs.b
            && lhs.c == rhs.c
            && lhs.d == rhs.d
            && lhs.e == rhs.e
    }
    
    static func + (lhs: Self, rhs: Self) -> Self {
        Self(
            lhs.a &+ rhs.a,
            lhs.b &+ rhs.b,
            lhs.c &+ rhs.c,
            lhs.d &+ rhs.d,
            lhs.e &+ rhs.e
        ).reduced()
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        Self(
            (lhs.a &+ 0x007ffffffffffed0) &- rhs.a,
            (lhs.b &+ 0x007ffffffffffff0) &- rhs.b,
            (lhs.c &+ 0x007ffffffffffff0) &- rhs.c,
            (lhs.d &+ 0x007ffffffffffff0) &- rhs.d,
            (lhs.e &+ 0x007ffffffffffff0) &- rhs.e
        ).reduced()
    }
    
    prefix static func - (operand: Self) -> Self {
        .zero - operand
    }
    
    mutating func negate(if choice: Choice) {
        self = self.replaced(with: -self, if: choice)
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        lhs.assertBounds()
        rhs.assertBounds()
        
        let x = lhs
        let y = rhs
        let m = (
            b: 19 &* y.b,
            c: 19 &* y.c,
            d: 19 &* y.d,
            e: 19 &* y.e
        )
        
        let c0 = x.a <*> y.a &+ x.e <*> m.b &+ x.d <*> m.c &+ x.c <*> m.d &+ x.b <*> m.e
        let c1 = x.b <*> y.a &+ x.a <*> y.b &+ x.e <*> m.c &+ x.d <*> m.d &+ x.c <*> m.e &+> (c0 &>> 51).low
        let c2 = x.c <*> y.a &+ x.b <*> y.b &+ x.a <*> y.c &+ x.e <*> m.d &+ x.d <*> m.e &+> (c1 &>> 51).low
        let c3 = x.d <*> y.a &+ x.c <*> y.b &+ x.b <*> y.c &+ x.a <*> y.d &+ x.e <*> m.e &+> (c2 &>> 51).low
        let c4 = x.e <*> y.a &+ x.d <*> y.b &+ x.c <*> y.c &+ x.b <*> y.d &+ x.a <*> y.e &+> (c3 &>> 51).low
        
        let a = (c0.low & mask51) &+ 19 &* (c4 &>> 51).low
        let b = (c1.low & mask51) &+ a &>> 51
        
        return Self(
            a & mask51,
            b,
            c2.low & mask51,
            c3.low & mask51,
            c4.low & mask51
        )
    }
    
    func squared() -> Self {
        self.assertBounds()
        
        let m = (
            d: 19 &* d,
            e: 19 &* e
        )
        
        let c0 = a <*>   a &+ (b <*> m.e &+ c <*> m.d).doubled()
        let c1 = d <*> m.d &+ (a <*>   b &+ c <*> m.e).doubled() &+> (c0 &>> 51).low
        let c2 = b <*>   b &+ (a <*>   c &+ e <*> m.d).doubled() &+> (c1 &>> 51).low
        let c3 = e <*> m.e &+ (a <*>   d &+ b <*>   c).doubled() &+> (c2 &>> 51).low
        let c4 = c <*>   c &+ (a <*>   e &+ b <*>   d).doubled() &+> (c3 &>> 51).low
        
        let a = (c0.low & mask51) &+ 19 &* (c4 &>> 51).low
        let b = (c1.low & mask51) &+ a &>> 51
        
        return Self(
            a & mask51,
            b,
            c2.low & mask51,
            c3.low & mask51,
            c4.low & mask51
        )
    }
    
    private func squaredRepeatedly(count: Int) -> Self {
        (0..<count).reduce(self) { x, _ in x.squared() }
    }
    
    private func powTwo250MinusOne() -> (result: Self, powEleven: Self) {
        let two = self.squared()
        let nine = self * two.squared().squared()
        let eleven = two * nine
        let two5MinusOne = nine * eleven.squared() // 2^5 - 1
        let two10MinusOne = two5MinusOne * two5MinusOne.squaredRepeatedly(count: 5)
        let two20MinusOne = two10MinusOne * two10MinusOne.squaredRepeatedly(count: 10)
        let two40MinusOne = two20MinusOne * two20MinusOne.squaredRepeatedly(count: 20)
        let two50MinusOne = two10MinusOne * two40MinusOne.squaredRepeatedly(count: 10)
        let two100MinusOne = two50MinusOne * two50MinusOne.squaredRepeatedly(count: 50)
        let two200MinusOne = two100MinusOne * two100MinusOne.squaredRepeatedly(count: 100)
        let two250MinusOne = two50MinusOne * two200MinusOne.squaredRepeatedly(count: 50)
        return (two250MinusOne, eleven)
    }
    
    func powTwo252MinusThree() -> Self {
        self * self.powTwo250MinusOne().result.squaredRepeatedly(count: 2)
    }
    
    func inverted() -> Self {
        let (two250MinusOne, eleven) = self.powTwo250MinusOne()
        return eleven * two250MinusOne.squaredRepeatedly(count: 5)
    }
    
    func squareRoot(over denominator: Self) -> (result: Self, wasSquare: Choice) {
        let three = denominator * denominator.squared()
        let seven = denominator * three.squared()
        
        var r = (self * three) * (self * seven).powTwo252MinusThree()
        let check = denominator * r.squared()
        
        let selfNegated = -self
        let isSignCorrect          = check == self
        let isSignFlipped          = check == selfNegated
        let isSignOfInverseFlipped = check == selfNegated * squareRootMinusOne
        
        r = r.replaced(with: r * squareRootMinusOne, if: isSignFlipped || isSignOfInverseFlipped)
        
        return (abs(r), isSignCorrect || isSignFlipped)
    }
    
    func inverseSquareRoot() -> (result: Self, wasSquare: Choice) {
        Self.one.squareRoot(over: self)
    }
    
    private func reduced() -> Self {
        Self(
            (a & mask51) &+ (e &>> 51) &* 19,
            (b & mask51) &+ (a &>> 51),
            (c & mask51) &+ (b &>> 51),
            (d & mask51) &+ (c &>> 51),
            (e & mask51) &+ (d &>> 51)
        )
    }
    
    private var q: UInt64 {
        [a, b, c, d, e].reduce(19) {
            ($0 &+ $1) &>> 51
        }
    }
    
    func canonicalized() -> Self {
        let reduced = self.reduced()
        
        let a = reduced.a &+ 19 &* reduced.q
        let b = reduced.b &+ (a &>> 51)
        let c = reduced.c &+ (b &>> 51)
        let d = reduced.d &+ (c &>> 51)
        let e = reduced.e &+ (d &>> 51)
        
        return FieldElement(
            a & mask51,
            b & mask51,
            c & mask51,
            d & mask51,
            e & mask51
        )
    }
}

func abs(_ x: FieldElement) -> FieldElement {
    x.replaced(with: -x, if: x.isNegative)
}

extension FieldElement {
    func replaced(with other: Self, if choice: Choice) -> Self {
        let mask = UInt64(maskFrom: choice)
        return FieldElement(
            (a & ~mask) | (other.a & mask),
            (b & ~mask) | (other.b & mask),
            (c & ~mask) | (other.c & mask),
            (d & ~mask) | (other.d & mask),
            (e & ~mask) | (other.e & mask)
        )
    }
}
