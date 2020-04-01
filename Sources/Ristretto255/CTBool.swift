struct CTBool: Equatable {
    static let `true`  = Self(0x01 as UInt8)
    static let `false` = Self(0x00 as UInt8)
    
    let rawValue: UInt8
    
    init(_ source: Self) {
        self = source
    }
    
    init(_ rawValue: UInt8) {
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = rawValue
    }
    
    init(_ rawValue: Int8) {
        let rawValue = UInt8(bitPattern: rawValue)
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = rawValue
    }
    
    fileprivate init(_ rawValue: UInt64) {
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = UInt8(truncatingIfNeeded: rawValue)
    }
    
    prefix static func ! (operand: Self) -> Self {
        Self(operand.rawValue ^ 0x01)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    static func && (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue & rhs.rawValue)
    }
    
    static func || (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue | rhs.rawValue)
    }
}

extension Bool {
    init(_ source: CTBool) {
        self = (source == .true)
    }
}

extension UInt8 {
    static func == (lhs: Self, rhs: Self) -> CTBool {
        CTBool([4, 2, 1].reduce(~(lhs ^ rhs)) { x, n in
            x & (x &>> n)
        })
    }
}

extension Int8 {
    static func == (lhs: Self, rhs: Self) -> CTBool {
        UInt8(bitPattern: lhs) == UInt8(bitPattern: rhs)
    }
}

extension UInt64 {
    static func == (lhs: Self, rhs: Self) -> CTBool {
        CTBool([32, 16, 8, 4, 2, 1].reduce(~(lhs ^ rhs)) { x, n in
            x & (x &>> n)
        })
    }
}
