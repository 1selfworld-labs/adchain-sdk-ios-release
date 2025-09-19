import UIKit

class WebViewStackManager {
    
    // MARK: - Singleton
    static let shared = WebViewStackManager()
    
    // MARK: - Properties
    private var webViewStack: [Weak<AdchainOfferwallViewController>] = []
    private let stackLock = NSLock()
    
    private init() {}
    
    // MARK: - Stack Management
    
    func push(_ viewController: AdchainOfferwallViewController) {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        // Remove any nil references
        webViewStack = webViewStack.filter { $0.value != nil }
        
        // Add new view controller
        webViewStack.append(Weak(viewController))
        
        AdchainLogger.d("WebViewStackManager", "WebView pushed to stack. Stack size: \(webViewStack.count)")
    }
    
    func pop() -> AdchainOfferwallViewController? {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        // Remove any nil references
        webViewStack = webViewStack.filter { $0.value != nil }
        
        // Pop last item
        if let weakRef = webViewStack.popLast() {
            AdchainLogger.d("WebViewStackManager", "WebView popped from stack. Remaining: \(webViewStack.count)")
            return weakRef.value
        }
        
        return nil
    }
    
    func peek() -> AdchainOfferwallViewController? {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        // Remove any nil references
        webViewStack = webViewStack.filter { $0.value != nil }
        
        return webViewStack.last?.value
    }
    
    func closeAll() {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        AdchainLogger.d("WebViewStackManager", "Closing all WebViews. Stack size: \(webViewStack.count)")
        
        // Close all view controllers in reverse order
        while !webViewStack.isEmpty {
            if let weakRef = webViewStack.popLast(),
               let viewController = weakRef.value {
                DispatchQueue.main.async {
                    viewController.dismiss(animated: false)
                }
            }
        }
        
        webViewStack.removeAll()
    }
    
    func remove(_ viewController: AdchainOfferwallViewController) {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        webViewStack = webViewStack.filter { $0.value != nil && $0.value !== viewController }
        
        AdchainLogger.d("WebViewStackManager", "WebView removed from stack. Stack size: \(webViewStack.count)")
    }
    
    var count: Int {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        // Remove any nil references and return count
        webViewStack = webViewStack.filter { $0.value != nil }
        return webViewStack.count
    }
    
    var isEmpty: Bool {
        return count == 0
    }
    
    func clear() {
        stackLock.lock()
        defer { stackLock.unlock() }
        
        webViewStack.removeAll()
        AdchainLogger.d("WebViewStackManager", "WebView stack cleared")
    }
}

