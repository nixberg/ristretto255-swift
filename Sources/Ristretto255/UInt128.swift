infix operator &+>: AdditionPrecedence
infix operator &+>=: AdditionPrecedence

struct UInt128 {
    let high: UInt64
    let low: UInt64
    
    init() {
        high = 0
        low = 0
    }
    
    init(_ source: UInt128) {
        self = source
    }
    
    init(_ high: UInt64, _ low: UInt64) {
        self.high = high
        self.low = low
    }
    
    // NOTE: The optimizer seems to do the right thing.
    static func &+ (lhs: UInt128, rhs: UInt128) -> UInt128 {
        let (low, overflow) = lhs.low.addingReportingOverflow(rhs.low)
        return UInt128(lhs.high &+ rhs.high &+ (overflow ? 1 : 0), low)
    }
    
    static func &+> (lhs: UInt128, rhs: UInt64) -> UInt128 {
        let (low, overflow) = lhs.low.addingReportingOverflow(rhs)
        return UInt128(lhs.high &+ (overflow ? 1 : 0), low)
    }
    
    static func &+>= (lhs: inout UInt128, rhs: UInt64) {
        lhs = lhs &+> rhs
    }
    
    static func &>> (lhs: UInt128, rhs: Int) -> UInt128 {
        return UInt128(lhs.high &>> rhs, (lhs.high &<< (64 &- rhs)) | (lhs.low &>> rhs))
    }
    
    func doubled() -> UInt128 {
        self &+ self
    }
}

infix operator <*>: MultiplicationPrecedence

extension UInt64 {
    static func <*> (lhs: UInt64, rhs: UInt64) -> UInt128 {
        let (high, low) = lhs.multipliedFullWidth(by: rhs)
        return UInt128(high, low)
    }
}
