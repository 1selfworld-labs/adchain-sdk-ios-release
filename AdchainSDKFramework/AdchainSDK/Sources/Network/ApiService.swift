import Foundation

protocol ApiService {
    func validateApp(_ request: ValidateAppRequest) async throws -> ValidateAppResponse
    func trackEvent(_ request: TrackEventRequest) async throws
    func getQuizEvents() async throws -> QuizResponse
    func getMissions() async throws -> MissionResponse
}

class ApiServiceImpl: ApiService {
    private let baseURL: String
    private let session: URLSession
    private let config: AdchainSdkConfig
    
    init(baseURL: String, config: AdchainSdkConfig) {
        self.baseURL = baseURL
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout
        
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Helper Methods
    private func createAuthenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.appKey, forHTTPHeaderField: ApiConfig.Headers.appKey)
        request.setValue(config.appSecret, forHTTPHeaderField: ApiConfig.Headers.appSecret)
        request.setValue("1.0.0", forHTTPHeaderField: ApiConfig.Headers.sdkVersion)
        request.setValue("iOS", forHTTPHeaderField: ApiConfig.Headers.platform)
        return request
    }
    
    func validateApp(_ request: ValidateAppRequest) async throws -> ValidateAppResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.validateApp)")!
        var urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        //let encoder = JSONEncoder()
        //urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        // Debug logging
        if let httpResponse = response as? HTTPURLResponse {
            print("=== ValidateApp Response Debug ===")
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print raw JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        }
        
        // Try to decode
        let decoder = JSONDecoder()
        do {
            let validationResponse = try decoder.decode(ValidateAppResponse.self, from: data)
            print("Successfully decoded response: \(validationResponse)")
            return validationResponse
        } catch {
            print("Decoding error: \(error)")
            
            // Try to parse as dictionary to see structure
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Response as Dictionary: \(json)")
                if let app = json["app"] as? [String: Any] {
                    print("App object contents: \(app)")
                }
            }
            
            throw error
        }
    }

    func login(_ request: LoginRequest) async throws -> ValidateAppResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.login)")!
        var urlRequest = createAuthenticatedRequest(url: url, method: "POST")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        // Debug logging
        if let httpResponse = response as? HTTPURLResponse {
            print("=== Login Response Debug ===")
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print raw JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        }
        
        // Try to decode
        let decoder = JSONDecoder()
        do {
            let validationResponse = try decoder.decode(LoginResponse.self, from: data)
            print("Successfully decoded response: \(validationResponse)")
            return validationResponse
        } catch {
            print("Decoding error: \(error)")
            
            // Try to parse as dictionary to see structure
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Response as Dictionary: \(json)")
                if let app = json["app"] as? [String: Any] {
                    print("App object contents: \(app)")
                }
            }
            
            throw error
        }
    }

    
    func trackEvent(_ request: TrackEventRequest) async throws {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.trackEvent)")!
        var urlRequest = createAuthenticatedRequest(url: url, method: "POST")
        
        // Convert request to dictionary and then to JSON
        let dict: [String: Any] = [
            "name": request.name,
            "timestamp": request.timestamp,
            "session_id": request.sessionId,
            "device_id": request.deviceId,
            "os": request.os,
            "os_version": request.osVersion,
            "parameters": request.parameters,
            "user_id": request.userId as Any,
            "advertising_id": request.advertisingId as Any
        ].compactMapValues { $0 }
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: dict)
        
        _ = try await session.data(for: urlRequest)
    }
    
    func getQuizEvents() async throws -> QuizResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.getQuizEvents)")!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = JSONDecoder()
        return try decoder.decode(QuizResponse.self, from: data)
    }
    
    func getMissions() async throws -> MissionResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.getMissions)")!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = JSONDecoder()
        return try decoder.decode(MissionResponse.self, from: data)
    }
}