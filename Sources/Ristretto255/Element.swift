import Foundation

fileprivate let d = FieldElement(
    0x00034dca135978a3,
    0x0001a8283b156ebd,
    0x0005e7a26001c029,
    0x000739c663a03cbb,
    0x00052036cee2b6ff
)

extension Element {
    public static let generator = Element(
        FieldElement(0x00062d608f25d51a, 0x000412a4b4f6592a, 0x00075b7171a4b31d, 0x0001ff60527118fe, 0x000216936d3cd6e5),
        FieldElement(0x0006666666666658, 0x0004cccccccccccc, 0x0001999999999999, 0x0003333333333333, 0x0006666666666666),
        FieldElement(1),
        FieldElement(0x00068ab3a5b7dda3, 0x00000eea2a5eadbb, 0x0002af8df483c27e, 0x000332b375274732, 0x00067875f0fd78b7)
    )
}

fileprivate let generatorLookupTable = GeneratorLookupTable()

public struct Element: Equatable {
    let x: FieldElement
    let y: FieldElement
    let z: FieldElement
    let t: FieldElement
        
    init() {
        x = zero
        y = one
        z = one
        t = zero
    }
    
    init(_ x: FieldElement, _ y: FieldElement, _ z: FieldElement, _ t: FieldElement) {
        self.x = x
        self.y = y
        self.z = z
        self.t = t
    }
    
    init(_ element: Completed) {
       x = element.x * element.t
       y = element.y * element.z
       z = element.z * element.t
       t = element.x * element.y
    }
    
    public init<D>(from data: D) where D: DataProtocol {
        precondition(data.count == 32)
        
        let s = FieldElement(from: data)
        guard zip(data, s.encoded()).map(^).reduce(0, |) == 0 else {
            fatalError()
        }
        
        guard Bool(s.isPositive) else {
            fatalError()
        }
        
        let sSquare = s.squared()
        let u1 = one - sSquare
        let u2 = one + sSquare
        let u2Squared = u2.squared()
        
        let v = -(d * u1.squared()) - u2Squared
        
        let (wasSquare, inverseSquareRoot) = (v * u2Squared).inverseSquareRoot()
        
        let denX = inverseSquareRoot * u2
        let denY = inverseSquareRoot * denX * v
        
        x = abs((s + s) * denX)
        y = u1 * denY
        z = one
        t = x * y
        
        guard Bool(wasSquare && t.isPositive && !y.isZero) else {
            fatalError()
        }
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
            0x00055aaa44ed4d20,
            0x00059603c3332635,
            0x00026d3baf4a7928,
            0x000120a66e6997a9,
            0x0005968b37af66c2
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
        let u = (r + one) * oneMinusDSquared
        let v = (minusOne - r * d) * (r + d)
        
        var (wasSquare, s) = u.squareRoot(over: v)
        let sPrime = -abs(s * t)
        s = wasSquare.select(s, else: sPrime)
        let c = wasSquare.select(minusOne, else: r)
        
        let n = c * (r - one) * dMinusOneSquared - v
        
        let sSquared = s.squared()
        
        let w0 = (s + s) * v
        let w1 = n * squareRootATimesDMinusOne
        let w2 = one - sSquared
        let w3 = one + sSquared
        
        self = Element(
            w0 * w3,
            w2 * w1,
            w1 * w3,
            w0 * w2
        )
    }
    
    public init<D>(fromUniformBytes data: D) where D: DataProtocol{
        precondition(data.count == 64)
        self = Element(mapping: FieldElement(from: data.prefix(32))) +
               Element(mapping: FieldElement(from: data.suffix(32)))
    }
    
    public static func random() -> Element {
        Element(fromUniformBytes: (0..<64).map { _ in UInt8.random(in: 0...255) })
    }
    
    public func encoded() -> [UInt8] {
        let inverseSquareRootMinusOneMinusD = FieldElement(
            0x0000fdaa805d40ea,
            0x0002eb482e57d339,
            0x000007610274bc58,
            0x0006510b613dc8ff,
            0x000786c8905cfaff
        )
        
        let u1 = (z + y) * (z - y)
        let u2 = x * y
        
        let (_, inverseSquareRoot) = (u1 * u2.squared()).inverseSquareRoot()
        
        let den1 = u1 * inverseSquareRoot
        let den2 = u2 * inverseSquareRoot
        let zInverted = den1 * den2 * t
        
        let rotate = (t * zInverted).isNegative
        let x = rotate.select(self.y * squareRootMinusOne, else: self.x)
        var y = rotate.select(self.x * squareRootMinusOne, else: self.y)
        let denInverted = rotate.select(den1 * inverseSquareRootMinusOneMinusD, else: den2)
        
        y = (x * zInverted).isNegative.select(-y, else: y)
        
        let s = abs(denInverted * (z - y))
        
        return s.encoded()
    }
    
    public static func == (lhs: Element, rhs: Element) -> Bool {
        Bool((lhs.x * rhs.y == lhs.y * rhs.x) || (lhs.y * rhs.y == lhs.x * rhs.x))
    }
    
    public static func + (lhs: Element, rhs: Element) -> Element {
        Element(lhs + ProjectiveNiels(rhs))
    }
    
    public static func - (lhs: Element, rhs: Element) -> Element {
        Element(lhs - ProjectiveNiels(rhs))
    }
    
    public static func * (lhs: Scalar, rhs: Element) -> Element {
        let lookupTable = LookupTable(from: rhs)
        let digits = lhs.radix16()
        let initial = Element() + lookupTable[digits[63]]
        return Element(digits.prefix(63).reversed().reduce(initial, {
            $0.times16() + lookupTable[$1]
        }))
    }
    
    func multipliedByPow2(_ k: UInt32) -> Element {
        Element((0..<(k &- 1)).reduce(Projective(self), { (e, _) in
            Projective(e.doubled())
        }).doubled())
    }
    
    public init(generatorTimes scalar: Scalar) {
        let digits = scalar.radix16()
        
        var sum = stride(from: 1, to: 64, by: 2).reduce(Element(), { (e, i) in
            Element(e + generatorLookupTable[i / 2, digits[i]])
        })
        
        sum = sum.multipliedByPow2(4)
        
        self = stride(from: 0, to: 64, by: 2).reduce(sum, { (e, i) in
            Element(e + generatorLookupTable[i / 2, digits[i]])
        })
    }
}
