import Subtle
import Foundation

fileprivate let d = FieldElement(
    0x00034dca135978a3,
    0x0001a8283b156ebd,
    0x0005e7a26001c029,
    0x000739c663a03cbb,
    0x00052036cee2b6ff
)

fileprivate let generatorLookupTable = GeneratorLookupTable()

public struct Element: Equatable {
    let x: FieldElement
    let y: FieldElement
    let z: FieldElement
    let t: FieldElement
    
    static let zero = Self(.zero, .one, .one, .zero)
    
    public static let generator = Self(
        FieldElement(0x00062d608f25d51a, 0x000412a4b4f6592a, 0x00075b7171a4b31d, 0x0001ff60527118fe, 0x000216936d3cd6e5),
        FieldElement(0x0006666666666658, 0x0004cccccccccccc, 0x0001999999999999, 0x0003333333333333, 0x0006666666666666),
        .one,
        FieldElement(0x00068ab3a5b7dda3, 0x00000eea2a5eadbb, 0x0002af8df483c27e, 0x000332b375274732, 0x00067875f0fd78b7)
    )
    
    init(_ x: FieldElement, _ y: FieldElement, _ z: FieldElement, _ t: FieldElement) {
        self.x = x
        self.y = y
        self.z = z
        self.t = t
    }
    
    init(_ source: Completed) {
       x = source.x * source.t
       y = source.y * source.z
       z = source.z * source.t
       t = source.x * source.y
    }
    
    public init?<Input>(from input: Input) where Input: DataProtocol {
        precondition(input.count == 32)
        
        guard let s = FieldElement(from: input) else {
            return nil
        }
        
        if Bool(s.isNegative) {
            return nil
        }
        
        let sSquared = s.squared()
        let u1 = .one - sSquared
        let u2 = .one + sSquared
        let u2Squared = u2.squared()
        
        let v = -(d * u1.squared()) - u2Squared
        
        let (inverseSquareRoot, wasSquare) = (v * u2Squared).inverseSquareRoot()
        
        let denX = inverseSquareRoot * u2
        let denY = inverseSquareRoot * denX * v
        
        x = abs((s + s) * denX)
        y = u1 * denY
        z = .one
        t = x * y
        
        if Bool(!wasSquare || t.isNegative || y.isZero) {
            return nil
        }
    }
    
    public init<Input>(fromUniformBytes input: Input) where Input: DataProtocol {
        precondition(input.count == 64)
        
        let r0 = FieldElement(canonicalizing: input.prefix(32))
        let r1 = FieldElement(canonicalizing: input.suffix(32))
        
        self = Self(mapping: r0) + Self(mapping: r1)
    }
    
    public static func random() -> Self {
        var rng = SystemRandomNumberGenerator()
        return Self(fromUniformBytes: (0..<64).map { _ in rng.next() })
    }
    
    private init(mapping t: FieldElement) {
        let minusOne = FieldElement(
            0x0007ffffffffffec,
            0x0007ffffffffffff,
            0x0007ffffffffffff,
            0x0007ffffffffffff,
            0x0007ffffffffffff
        )
        let oneMinusDSquared = FieldElement(
            0x000409c1945fc176,
            0x000719abc6a1fc4f,
            0x0001c37f90b20684,
            0x00006bccca55eedf,
            0x000029072a8b2b3e
        )
        let dMinusOneSquared = FieldElement(
            0x00055aaa44ed4d20,
            0x00059603c3332635,
            0x00026d3baf4a7928,
            0x000120a66e6997a9,
            0x0005968b37af66c2
        )
        let squareRootATimesDMinusOne = FieldElement(
            0x0007f6a0497b2e1b,
            0x0001836f0a97afd2,
            0x0007d747f6be7638,
            0x000456079e7e6498,
            0x000376931bf2b834
        )
        
        let r = squareRootMinusOne * t.squared()
        var c = minusOne
        let u = (r + .one) * oneMinusDSquared
        let v = (c - d * r) * (r + d)
        
        var (s, wasSquare) = u.squareRoot(over: v)
        let sPrime = -abs(s * t)
        s = s.replaced(with: sPrime, if: !wasSquare)
        c = c.replaced(with: r, if: !wasSquare)
        
        let n = c * (r - .one) * dMinusOneSquared - v
        
        let sSquared = s.squared()
        
        let w0 = (s + s) * v
        let w1 = n * squareRootATimesDMinusOne
        let w2 = .one - sSquared
        let w3 = .one + sSquared
        
        self = Self(
            w0 * w3,
            w2 * w1,
            w1 * w3,
            w0 * w2
        )
    }
    
    public func encode<Output>(to output: inout Output) where Output: MutableDataProtocol {
        let inverseSquareRootMinusOneMinusD = FieldElement(
            0x0000fdaa805d40ea,
            0x0002eb482e57d339,
            0x000007610274bc58,
            0x0006510b613dc8ff,
            0x000786c8905cfaff
        )
        
        let u1 = (z + y) * (z - y)
        let u2 = x * y
        
        let inverseSquareRoot = (u1 * u2.squared()).inverseSquareRoot().result
        
        let den1 = u1 * inverseSquareRoot
        let den2 = u2 * inverseSquareRoot
        let zInverted = den1 * den2 * t
        
        let mustRotate = (t * zInverted).isNegative
        let x = self.x.replaced(with: self.y * squareRootMinusOne, if: mustRotate)
        var y = self.y.replaced(with: self.x * squareRootMinusOne, if: mustRotate)
        let denInverted = den2.replaced(
            with: den1 * inverseSquareRootMinusOneMinusD, if: mustRotate)
        
        y.negate(if: (x * zInverted).isNegative)
        
        abs(denInverted * (z - y)).encode(to: &output)
    }
    
    public func encoded() -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(32)
        self.encode(to: &output)
        return output
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        Bool((lhs.x * rhs.y == lhs.y * rhs.x) || (lhs.y * rhs.y == lhs.x * rhs.x))
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs + ProjectiveNiels(rhs))
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs - ProjectiveNiels(rhs))
    }
    
    public static func * (lhs: Scalar, rhs: Self) -> Self {
        let lookupTable = LookupTable(for: rhs)
        let digits = SignedRadix16(from: lhs)
        return Self((0..<63).reversed().reduce(.zero + lookupTable[digits[63]]) {
            $0.multipliedBy16() + lookupTable[digits[$1]]
        })
    }
    
    func doubledRepeatedly(count: Int) -> Self {
        Self((0..<(count - 1)).reduce(Projective(self)) { element, _ in
            Projective(element.doubled())
        }.doubled())
    }
    
    public init(generatorTimes scalar: Scalar) {
        let digits = SignedRadix16(from: scalar)
        
        var sum = stride(from: 1, to: 64, by: 2).reduce(.zero) {
            Self($0 + generatorLookupTable[$1 / 2, digits[$1]])
        }
        
        sum = sum.doubledRepeatedly(count: 4)
        
        self = stride(from: 0, to: 64, by: 2).reduce(sum) {
            Self($0 + generatorLookupTable[$1 / 2, digits[$1]])
        }
    }
}
