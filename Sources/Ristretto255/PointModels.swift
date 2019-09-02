fileprivate let dTimesTwo = FieldElement(
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
    
    func times16() -> Element {
        let two = Projective(self).doubled()
        let four = Projective(two).doubled()
        let eight = Projective(four).doubled()
        return Element(Projective(eight).doubled())
    }
}

struct Projective {
    let x: FieldElement
    let y: FieldElement
    let z: FieldElement
    
    init() {
        x = zero
        y = one
        z = one
    }
    
    init(_ element: Completed) {
        x = element.x * element.t
        y = element.y * element.z
        z = element.z * element.t
    }
    
    init(_ element: Element) {
        x = element.x
        y = element.y
        z = element.z
    }
    
    func doubled() -> Completed {
        let xSquared = x.squared()
        let ySquared = y.squared()
        let ySquaredPlusXSquared = ySquared + xSquared
        let ySquaredMinusXSquared = ySquared - xSquared
        
        return Completed(
            (x + y).squared() - ySquaredPlusXSquared,
            ySquaredPlusXSquared,
            ySquaredMinusXSquared,
            z.squaredTimesTwo() - ySquaredMinusXSquared
        )
    }
}

struct ProjectiveNiels {
    let yPlusX: FieldElement
    let yMinusX: FieldElement
    let z: FieldElement
    let tTimesTwoD: FieldElement
    
    init() {
        yPlusX = one
        yMinusX = one
        z = one
        tTimesTwoD = zero
    }
    
    init(_ yPlusX: FieldElement, _ yMinusX: FieldElement, _ z: FieldElement, _ tTimes2D: FieldElement) {
        self.yPlusX = yPlusX
        self.yMinusX = yMinusX
        self.z = z
        self.tTimesTwoD = tTimes2D
    }
    
    init(_ element: Element) {
        yPlusX = element.y + element.x
        yMinusX = element.y - element.x
        z = element.z
        tTimesTwoD = element.t * dTimesTwo
    }
    
    prefix static func - (x: ProjectiveNiels) -> ProjectiveNiels {
        ProjectiveNiels(
            x.yMinusX,
            x.yPlusX,
            x.z,
            -x.tTimesTwoD
        )
    }
    
    static func + (lhs: Element, rhs: ProjectiveNiels) -> Completed {
        let pp = (lhs.y + lhs.x) * rhs.yPlusX
        let mm = (lhs.y - lhs.x) * rhs.yMinusX
        let ttTimesTwoD = lhs.t * rhs.tTimesTwoD
        let zz = lhs.z * rhs.z
        let zzTimesTwo = zz + zz

        return Completed(
            pp - mm,
            pp + mm,
            zzTimesTwo + ttTimesTwoD,
            zzTimesTwo - ttTimesTwoD
        )
    }
    
    static func - (lhs: Element, rhs: ProjectiveNiels) -> Completed {
        let pm = (lhs.y + lhs.x) * rhs.yMinusX
        let mp = (lhs.y - lhs.x) * rhs.yPlusX
        let ttTimesTwoD = lhs.t * rhs.tTimesTwoD
        let zz = lhs.z * rhs.z
        let zzTimesTwo = zz + zz
        
        return Completed(
            pm - mp,
            pm + mp,
            zzTimesTwo - ttTimesTwoD,
            zzTimesTwo + ttTimesTwoD
        )
    }
}

struct AffineNiels {
    let yPlusX: FieldElement
    let yMinusX: FieldElement
    let xyTimesTwoD: FieldElement
    
    init() {
        yPlusX = one
        yMinusX = one
        xyTimesTwoD = zero
    }
    
    init(_ yPlusX: FieldElement, _ yMinusX: FieldElement, _ xyTimes2D: FieldElement) {
        self.yPlusX = yPlusX
        self.yMinusX = yMinusX
        self.xyTimesTwoD = xyTimes2D
    }
    
    init(_ element: Element) {
        let zInverted = element.z.inverted()
        let x = element.x * zInverted
        let y = element.y * zInverted
        yPlusX = y + x
        yMinusX = y - x
        xyTimesTwoD = (x * y) * dTimesTwo
    }
    
    prefix static func - (p: AffineNiels) -> AffineNiels {
        AffineNiels(
            p.yMinusX,
            p.yPlusX,
            -p.xyTimesTwoD
        )
    }
    
    static func + (lhs: Element, rhs: AffineNiels) -> Completed {
        let pp = (lhs.y + lhs.x) * rhs.yPlusX
        let mm = (lhs.y - lhs.x) * rhs.yMinusX
        let tTimesXYTimesTwoD = lhs.t * rhs.xyTimesTwoD
        let zTimesTwo = lhs.z + lhs.z
        
        return Completed(
            pp - mm,
            pp + mm,
            zTimesTwo + tTimesXYTimesTwoD,
            zTimesTwo - tTimesXYTimesTwoD
        )
    }
}
