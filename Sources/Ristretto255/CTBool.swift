struct CTBool: Equatable {
    static let one  = CTBool(UInt8(0x01)) // true
    static let zero = CTBool(UInt8(0x00)) // false
    
    let rawValue: UInt8
    
    init(_ value: CTBool) {
        self = value
    }
    
    init(_ rawValue: UInt8) {
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = rawValue
    }
    
    init(_ rawValue: Int8) {
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = UInt8(rawValue)
    }
    
    prefix static func ! (a: CTBool) -> CTBool {
        CTBool(a.rawValue ^ 0x01)
    }
        
    static func == (lhs: CTBool, rhs: CTBool) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    static func && (lhs: CTBool, rhs: CTBool) -> CTBool {
        CTBool(lhs.rawValue & rhs.rawValue)
    }
    
    static func || (lhs: CTBool, rhs: CTBool) -> CTBool {
        CTBool(lhs.rawValue | rhs.rawValue)
    }
}

extension Bool {
    init(_ value: CTBool) {
        self = (value == CTBool.one)
    }
}

extension UInt8 {
    static func == (lhs: UInt8, rhs: UInt8) -> CTBool {
        CTBool([4, 2, 1].reduce(~(lhs ^ rhs), { x, n in
            x & (x &>> n)
        }))
    }
}

extension Int8 {
    static func == (lhs: Int8, rhs: Int8) -> CTBool {
        UInt8(bitPattern: lhs) == UInt8(bitPattern: rhs)
    }
}

extension Array where Element == UInt8 {
    static func == (lhs: [UInt8], rhs: [UInt8]) -> CTBool {
        precondition(lhs.count == rhs.count)
        return zip(lhs, rhs).map(==).reduce(CTBool.one, &&)
    }
}
