import Foundation

class AuthInterceptor: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Check if we've already handled this request
        guard URLProtocol.property(forKey: "AuthInterceptor", in: request) == nil else {
            return false
        }
        
        // Only intercept our API requests
        if let url = request.url?.absoluteString {
            return url.contains("api.adchain.com") ||
                   url.contains("staging-api.adchain.com") ||
                   url.contains("dev-api.adchain.com")
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        var newRequest = request
        
        // Add authentication headers
        if let config = AdchainSdk.shared.getConfig() {
            newRequest.setValue(config.appKey, forHTTPHeaderField: ApiConfig.Headers.appKey)
            newRequest.setValue(config.appSecret, forHTTPHeaderField: ApiConfig.Headers.appSecret)
        }
        
        // Add SDK version
        if let version = Bundle(for: AdchainSdk.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            newRequest.setValue("AdchainSDK/\(version)", forHTTPHeaderField: ApiConfig.Headers.userAgent)
        }
        
        // Mark as handled
        URLProtocol.setProperty(true, forKey: "AuthInterceptor", in: newRequest as! NSMutableURLRequest)
        
        // Forward the request
        let session = URLSession.shared
        let task = session.dataTask(with: newRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else if let response = response, let data = data {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        task.resume()
    }
    
    override func stopLoading() {
        // Cancel any ongoing tasks if needed
    }
}