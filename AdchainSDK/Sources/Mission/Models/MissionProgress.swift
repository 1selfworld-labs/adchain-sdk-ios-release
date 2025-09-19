import Foundation

public struct MissionProgress: Sendable {
    public let current: Int
    public let total: Int
    
    public var percentage: Float {
        guard total > 0 else { return 0 }
        return Float(current) / Float(total)
    }
    
    public var isCompleted: Bool {
        return current >= total
    }
    
    public init(current: Int, total: Int) {
        self.current = current
        self.total = total
    }
}