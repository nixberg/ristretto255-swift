struct CTBool {
    static let `true`  = Self(0x01 as UInt8)
    static let `false` = Self(0x00 as UInt8)
    
    let rawValue: UInt8
    
    init<T>(_ rawValue: T) where T: FixedWidthInteger & UnsignedInteger {
        assert(rawValue & 0x01 == rawValue)
        self.rawValue = UInt8(truncatingIfNeeded: rawValue)
    }
    
    prefix static func ! (operand: Self) -> Self {
        Self(operand.rawValue ^ 0x01)
    }
    
    static func && (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue & rhs.rawValue)
    }
    
    static func || (lhs: Self, rhs: Self) -> Self {
        Self(lhs.rawValue | rhs.rawValue)
    }
    
    func or(_ other: Self, if condition: Self) -> Self {
        (self && !condition) || (other && condition)
    }
}

extension Bool {
    init(_ source: CTBool) {
        self = source.rawValue == CTBool.true.rawValue
    }
}

extension FixedWidthInteger where Self: UnsignedInteger {
    static func == (lhs: Self, rhs: Self) -> CTBool {
        var result = lhs ^ rhs
        result |= 0 &- result
        result &>>= Self.bitWidth - 1
        return !CTBool(result)
    }
    
    static func < (lhs: Self, rhs: Self) -> CTBool {
        // From https://github.com/veorq/cryptocoding
        var result = lhs &- rhs
        result ^= rhs
        result |= lhs ^ rhs
        result ^= lhs
        result &>>= Self.bitWidth - 1
        return CTBool(result)
    }
}
