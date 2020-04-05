infix operator &+>: AdditionPrecedence
infix operator <*>: MultiplicationPrecedence

struct UInt128 {
    let high: UInt64
    let low: UInt64
    
    fileprivate init(_ high: UInt64, _ low: UInt64) {
        self.high = high
        self.low = low
    }
    
    // NOTE: The optimizer seems to do the right thing.
    @inline(__always)
    static func &+ (lhs: Self, rhs: Self) -> Self {
        let (low, overflow) = lhs.low.addingReportingOverflow(rhs.low)
        return Self(lhs.high &+ rhs.high &+ (overflow ? 1 : 0), low)
    }
    
    @inline(__always)
    static func &+> (lhs: Self, rhs: UInt64) -> Self {
        let (low, overflow) = lhs.low.addingReportingOverflow(rhs)
        return Self(lhs.high &+ (overflow ? 1 : 0), low)
    }
    
    @inline(__always)
    static func &>> (lhs: Self, rhs: Int) -> Self {
        return Self(lhs.high &>> rhs, (lhs.high &<< (64 - rhs)) | (lhs.low &>> rhs))
    }
    
    @inline(__always)
    func doubled() -> Self {
        self &+ self
    }
}

extension UInt64 {
    @inline(__always)
    static func <*> (lhs: Self, rhs: Self) -> UInt128 {
        let (high, low) = lhs.multipliedFullWidth(by: rhs)
        return UInt128(high, low)
    }
}
