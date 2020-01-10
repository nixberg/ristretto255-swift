struct LookupTable {
    private let table: [ProjectiveNiels]
    
    init(from element: Element) {
        var table = [ProjectiveNiels](repeating: ProjectiveNiels(element), count: 8)
        for i in 0..<7 {
            table[i &+ 1] = ProjectiveNiels(Element(element + table[i]))
        }
        self.table = table
    }
    
    subscript(index: Int8) -> ProjectiveNiels {
        let mask = index &>> 7
        let absIndex = ((index &+ mask) ^ mask)
        
        var t = ProjectiveNiels()
        for i in table.indices {
            t = (absIndex == Int8(i) &+ 1).then(table[i], else: t)
        }
        
        return CTBool(mask & 0x01).then(-t, else: t)
    }
}

struct GeneratorLookupTable {
    private let table: [[AffineNiels]]
    
    init() {
        var table = [[AffineNiels]]()
        
        var element = Element.generator
        for _ in 0..<32 {
            var row = [AffineNiels](repeating: AffineNiels(element), count: 8)
            for i in 0..<7 {
                row[i &+ 1] = AffineNiels(Element(element + row[i]))
            }
            table.append(row)
            element = element.times2(8)
        }
        self.table = table
    }
    
    subscript(row: Int, index: Int8) -> AffineNiels {
        let mask = index &>> 7
        let absIndex = ((index &+ mask) ^ mask)
        
        var t = AffineNiels()
        for i in table[row].indices {
            t = (absIndex == Int8(i) &+ 1).then(table[row][i], else: t)
        }
        
        return CTBool(mask & 0x01).then(-t, else: t)
     }
}

fileprivate extension CTBool {
    func then(_ `true`: ProjectiveNiels, else `false`: ProjectiveNiels) -> ProjectiveNiels {
        ProjectiveNiels(
            self.then(`true`.yPlusX, else: `false`.yPlusX),
            self.then(`true`.yMinusX, else: `false`.yMinusX),
            self.then(`true`.z, else: `false`.z),
            self.then(`true`.tTimesTwoD, else: `false`.tTimesTwoD)
        )
    }
    
    func then(_ `true`: AffineNiels, else `false`: AffineNiels) -> AffineNiels {
        AffineNiels(
            self.then(`true`.yPlusX, else: `false`.yPlusX),
            self.then(`true`.yMinusX, else: `false`.yMinusX),
            self.then(`true`.xyTimesTwoD, else: `false`.xyTimesTwoD)
        )
    }
}
