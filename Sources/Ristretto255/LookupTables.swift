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
            t = (absIndex == Int8(i) &+ 1).select(table[i], else: t)
       }
       
        return CTBool(mask & 0x01).select(-t, else: t)
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
            element = element.multipliedByPow2(8)
        }
        self.table = table
    }
    
    subscript(row: Int, index: Int8) -> AffineNiels {
        let mask = index &>> 7
        let absIndex = ((index &+ mask) ^ mask)
        
        var t = AffineNiels()
        for i in table[row].indices {
            t = (absIndex == Int8(i) &+ 1).select(table[row][i], else: t)
        }
        
        return CTBool(mask & 0x01).select(-t, else: t)
     }
}

extension CTBool {
    fileprivate func select(_ t: ProjectiveNiels, else f: ProjectiveNiels) -> ProjectiveNiels {
        ProjectiveNiels(
            self.select(t.yPlusX, else: f.yPlusX),
            self.select(t.yMinusX, else: f.yMinusX),
            self.select(t.z, else: f.z),
            self.select(t.tTimesTwoD, else: f.tTimesTwoD)
        )
    }
    
    fileprivate func select(_ t: AffineNiels, else f: AffineNiels) -> AffineNiels {
        AffineNiels(
            self.select(t.yPlusX, else: f.yPlusX),
            self.select(t.yMinusX, else: f.yMinusX),
            self.select(t.xyTimesTwoD, else: f.xyTimesTwoD)
        )
    }
}
