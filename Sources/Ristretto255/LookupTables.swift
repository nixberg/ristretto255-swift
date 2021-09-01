import Subtle

struct LookupTable {
    private let table: [ProjectiveNiels]
    
    init(for element: Element) {
        table = (1..<8).reduce(into: [ProjectiveNiels(element)]) { table, _ in
            table.append(ProjectiveNiels(Element(element + table.last!)))
        }
    }
    
    subscript(index: Int8) -> ProjectiveNiels {
        let mask = index >> 7
        let absoluteIndex = ((index &+ mask) ^ mask)
        
        var result = ProjectiveNiels.zero
        for (i, element) in table.enumerated() {
            result.replace(with: element, if: absoluteIndex == Int8(i + 1))
        }
        
        return result.negated(if: Choice(uncheckedRawValue: UInt8(truncatingIfNeeded: mask) & 0x01))
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
            }
            .prefix(32)
            .map(row(for:))
    }
    
    subscript(rowIndex: Int, index: Int8) -> AffineNiels {
        let mask = index >> 7
        let absoluteIndex = ((index &+ mask) ^ mask)
        
        var result = AffineNiels.zero
        for (i, element) in table[rowIndex].enumerated() {
            result.replace(with: element, if: absoluteIndex == Int8(i + 1))
        }
        
        return result.negated(if: Choice(uncheckedRawValue: UInt8(truncatingIfNeeded: mask) & 0x01))
     }
}

fileprivate extension ProjectiveNiels {
    private func replaced(with other: Self, if choice: Choice) -> Self {
        Self(
            yPlusX.replaced(with: other.yPlusX, if: choice),
            yMinusX.replaced(with: other.yMinusX, if: choice),
            z.replaced(with: other.z, if: choice),
            tTimesTwoD.replaced(with: other.tTimesTwoD, if: choice)
        )
    }
    
    mutating func replace(with other: Self, if choice: Choice) {
        self = self.replaced(with: other, if: choice)
    }
    
    func negated(if choice: Choice) -> Self {
        self.replaced(with: -self, if: choice)
    }
}

fileprivate extension AffineNiels {
    private func replaced(with other: Self, if choice: Choice) -> Self {
        Self(
            yPlusX.replaced(with: other.yPlusX, if: choice),
            yMinusX.replaced(with: other.yMinusX, if: choice),
            xyTimesTwoD.replaced(with: other.xyTimesTwoD, if: choice)
        )
    }
    
    mutating func replace(with other: Self, if choice: Choice) {
        self = self.replaced(with: other, if: choice)
    }
    
    func negated(if choice: Choice) -> Self {
        self.replaced(with: -self, if: choice)
    }
}

fileprivate extension Choice {
    init(_ rawValue: Int8) {
        self = Choice(uncheckedRawValue: UInt8(bitPattern: rawValue))
    }
}

fileprivate extension Int8 {
    static func == (lhs: Self, rhs: Self) -> Choice {
        UInt8(bitPattern: lhs) == UInt8(bitPattern: rhs)
    }
}
