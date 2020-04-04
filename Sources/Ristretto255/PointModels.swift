fileprivate let twoD = FieldElement(
    0x00069b9426b2f159,
    0x00035050762add7a,
    0x0003cf44c0038052,
    0x0006738cc7407977,
    0x0002406d9dc56dff
)

struct Completed {
    let x: FieldElement
    let y: FieldElement
    let z: FieldElement
    let t: FieldElement
    
    init(_ x: FieldElement, _ y: FieldElement, _ z: FieldElement, _ t: FieldElement) {
        self.x = x
        self.y = y
        self.z = z
        self.t = t
    }
    
    func multipliedBy16() -> Element {
        Element((0..<4).reduce(self) { element, _ in
            Projective(element).doubled()
        })
    }
}

struct Projective {
    let x: FieldElement
    let y: FieldElement
    let z: FieldElement
    
    init(_ source: Completed) {
        x = source.x * source.t
        y = source.y * source.z
        z = source.z * source.t
    }
    
    init(_ source: Element) {
        x = source.x
        y = source.y
        z = source.z
    }
    
    func doubled() -> Completed {
        let xSquared = x.squared()
        let ySquared = y.squared()
        let zSquared = z.squared()
        let ySquaredPlusXSquared = ySquared + xSquared
        let ySquaredMinusXSquared = ySquared - xSquared
        
        return Completed(
            (x + y).squared() - ySquaredPlusXSquared,
            ySquaredPlusXSquared,
            ySquaredMinusXSquared,
            (zSquared + zSquared) - ySquaredMinusXSquared
        )
    }
}

struct ProjectiveNiels {
    let yPlusX: FieldElement
    let yMinusX: FieldElement
    let z: FieldElement
    let tTimesTwoD: FieldElement
    
    static let zero = Self(.one, .one, .one, .zero)
    
    init(_ yPlusX: FieldElement, _ yMinusX: FieldElement, _ z: FieldElement, _ tTimesTwoD: FieldElement) {
        self.yPlusX = yPlusX
        self.yMinusX = yMinusX
        self.z = z
        self.tTimesTwoD = tTimesTwoD
    }
    
    init(_ other: Element) {
        yPlusX = other.y + other.x
        yMinusX = other.y - other.x
        z = other.z
        tTimesTwoD = other.t * twoD
    }
    
    prefix static func - (operand: Self) -> Self {
        Self(
            operand.yMinusX,
            operand.yPlusX,
            operand.z,
            -operand.tTimesTwoD
        )
    }
    
    static func + (lhs: Element, rhs: Self) -> Completed {
        let pp = (lhs.y + lhs.x) * rhs.yPlusX
        let mm = (lhs.y - lhs.x) * rhs.yMinusX
        let ttTimesTwoD = lhs.t * rhs.tTimesTwoD
        let zz = lhs.z * rhs.z
        let twoZZ = zz + zz
        
        return Completed(
            pp - mm,
            pp + mm,
            twoZZ + ttTimesTwoD,
            twoZZ - ttTimesTwoD
        )
    }
    
    static func - (lhs: Element, rhs: Self) -> Completed {
        let pm = (lhs.y + lhs.x) * rhs.yMinusX
        let mp = (lhs.y - lhs.x) * rhs.yPlusX
        let ttTimesTwoD = lhs.t * rhs.tTimesTwoD
        let zz = lhs.z * rhs.z
        let twoZZ = zz + zz
        
        return Completed(
            pm - mp,
            pm + mp,
            twoZZ - ttTimesTwoD,
            twoZZ + ttTimesTwoD
        )
    }
}

struct AffineNiels {
    let yPlusX: FieldElement
    let yMinusX: FieldElement
    let xyTimesTwoD: FieldElement
    
    static let zero = Self(.one, .one, .zero)
    
    init(_ yPlusX: FieldElement, _ yMinusX: FieldElement, _ xyTimesTwoD: FieldElement) {
        self.yPlusX = yPlusX
        self.yMinusX = yMinusX
        self.xyTimesTwoD = xyTimesTwoD
    }
    
    init(_ element: Element) {
        let zInverted = element.z.inverted()
        let x = element.x * zInverted
        let y = element.y * zInverted
        yPlusX = y + x
        yMinusX = y - x
        xyTimesTwoD = (x * y) * twoD
    }
    
    prefix static func - (operand: Self) -> Self {
        Self(
            operand.yMinusX,
            operand.yPlusX,
            -operand.xyTimesTwoD
        )
    }
    
    static func + (lhs: Element, rhs: Self) -> Completed {
        let pp = (lhs.y + lhs.x) * rhs.yPlusX
        let mm = (lhs.y - lhs.x) * rhs.yMinusX
        let tTimesXYTimesTwoD = lhs.t * rhs.xyTimesTwoD
        let twoZ = lhs.z + lhs.z
        
        return Completed(
            pp - mm,
            pp + mm,
            twoZ + tTimesXYTimesTwoD,
            twoZ - tTimesXYTimesTwoD
        )
    }
}
