struct LookupTable {
    private let table: [ProjectiveNiels]
    
    init(for element: Element) {
        table = (1..<8).reduce(into: [ProjectiveNiels(element)]) { table, _ in
            table.append(ProjectiveNiels(Element(element + table.last!)))
        }
    }
    
    subscript(index: Int8) -> ProjectiveNiels {
        let mask = index &>> 7
        let absoluteIndex = ((index &+ mask) ^ mask)
        
        var result = ProjectiveNiels.zero
        for (i, element) in table.enumerated() {
            result = result.or(element, if: absoluteIndex == Int8(i + 1))
        }
        
        return result.or(-result, if: CTBool(mask & 0x01))
    }
}

struct GeneratorLookupTable {
    private let table: [[AffineNiels]]
    
    init() {
        func row(for element: Element) -> [AffineNiels] {
            (1..<8).reduce(into: [AffineNiels(element)]) { table, _ in
                table.append(AffineNiels(Element(element + table.last!)))
            }
        }
        table = sequence(first: Element.generator) {
            $0.doubledRepeatedly(count: 8)
        }.prefix(32).map {
            row(for: $0)
        }
    }
    
    subscript(rowIndex: Int, index: Int8) -> AffineNiels {
        let mask = index &>> 7
        let absoluteIndex = ((index &+ mask) ^ mask)
        
        var result = AffineNiels.zero
        for (i, element) in table[rowIndex].enumerated() {
            result = result.or(element, if: absoluteIndex == Int8(i + 1))
        }
        
        return result.or(-result, if: CTBool(mask & 0x01))
     }
}

fileprivate extension ProjectiveNiels {
    func or(_ other: Self, if condition: CTBool) -> Self {
        Self(
            yPlusX.or(other.yPlusX, if: condition),
            yMinusX.or(other.yMinusX, if: condition),
            z.or(other.z, if: condition),
            tTimesTwoD.or(other.tTimesTwoD, if: condition)
        )
    }
}

fileprivate extension AffineNiels {
    func or(_ other: Self, if condition: CTBool) -> Self {
        Self(
            yPlusX.or(other.yPlusX, if: condition),
            yMinusX.or(other.yMinusX, if: condition),
            xyTimesTwoD.or(other.xyTimesTwoD, if: condition)
        )
    }
}

fileprivate extension CTBool {
    init(_ rawValue: Int8) {
        self.init(UInt8(bitPattern: rawValue))
    }
}

fileprivate extension Int8 {
    static func == (lhs: Self, rhs: Self) -> CTBool {
        UInt8(bitPattern: lhs) == UInt8(bitPattern: rhs)
    }
}
