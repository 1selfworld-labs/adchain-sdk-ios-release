import Foundation

@objc public class AdchainSdkConfig: NSObject {
    @objc public enum Environment: Int {
        case production = 0
        case staging = 1
        case development = 2
    }
    
    @objc public let appKey: String
    @objc public let appSecret: String
    @objc public let environment: Environment
    @objc public let timeout: TimeInterval
    
    private init(
        appKey: String,
        appSecret: String,
        environment: Environment,
        timeout: TimeInterval
    ) {
        self.appKey = appKey
        self.appSecret = appSecret
        self.environment = environment
        self.timeout = timeout
        super.init()
    }
    
    // MARK: - Builder Pattern (Android와 동일)
    @objc public class Builder: NSObject {
        private let appKey: String
        private let appSecret: String
        private var environment: Environment = .production
        private var timeout: TimeInterval = 30.0
        
        @objc public init(appKey: String, appSecret: String) {
            self.appKey = appKey
            self.appSecret = appSecret
            super.init()
        }
        
        @objc public func setEnvironment(_ environment: Environment) -> Builder {
            self.environment = environment
            return self
        }
        
        @objc public func setTimeout(_ timeout: TimeInterval) -> Builder {
            self.timeout = timeout
            return self
        }
        
        @objc public func build() -> AdchainSdkConfig {
            guard !appKey.isEmpty else {
                fatalError("App Key cannot be empty")
            }
            guard !appSecret.isEmpty else {
                fatalError("App Secret cannot be empty")
            }
            
            return AdchainSdkConfig(
                appKey: appKey,
                appSecret: appSecret,
                environment: environment,
                timeout: timeout
            )
        }
    }
}