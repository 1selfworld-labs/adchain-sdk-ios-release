import Foundation

// MARK: - Weak Reference Wrapper (공통 사용)
internal class Weak<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}