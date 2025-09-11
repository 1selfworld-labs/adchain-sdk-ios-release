import Foundation

// Banner response models - 서버 응답과 일치하는 구조로 변경
public struct BannerResponse: Codable, Sendable {
    public let success: Bool?
    public let imageUrl: String?
    public let titleText: String?
    public let linkUrl: String?
    public let message: String?
}

protocol ApiService {
    func validateApp() async throws -> ValidateAppResponse
    func login(_ request: LoginRequest) async throws -> LoginResponse
    func trackEvent(_ request: TrackEventRequest) async throws
    func getQuizEvents(userId: String?, platform: String?, ifa: String?) async throws -> QuizResponse
    func getMissions(userId: String?, platform: String?, ifa: String?) async throws -> MissionResponse
    func getBanner(userId: String, placementId: String, platform: String) async throws -> BannerResponse
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
    
    func validateApp() async throws -> ValidateAppResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.validateApp)")!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
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
    
    func login(_ request: LoginRequest) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)\(ApiConfig.Endpoints.login)")!
        var urlRequest = createAuthenticatedRequest(url: url, method: "POST")
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
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
            let response = try decoder.decode(LoginResponse.self, from: data)
            print("Successfully decoded response: \(response)")
            return response
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
        
        // request를 httpBody로 변환
        let httpBody = try JSONEncoder().encode(request)
        urlRequest.httpBody = httpBody
        
        _ = try await session.data(for: urlRequest)
    }
    
    func getQuizEvents(userId: String? = nil, platform: String? = nil, ifa: String? = nil) async throws -> QuizResponse {
        var urlComponents = URLComponents(string: "\(baseURL)\(ApiConfig.Endpoints.getQuizEvents)")!
        var queryItems: [URLQueryItem] = []
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        if let platform = platform {
            queryItems.append(URLQueryItem(name: "platform", value: platform))
        }
        if let ifa = ifa {
            queryItems.append(URLQueryItem(name: "ifa", value: ifa))
        }
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        let url = urlComponents.url!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = JSONDecoder()
        return try decoder.decode(QuizResponse.self, from: data)
    }
    
    func getMissions(userId: String? = nil, platform: String? = nil, ifa: String? = nil) async throws -> MissionResponse {
        var urlComponents = URLComponents(string: "\(baseURL)\(ApiConfig.Endpoints.getMissions)")!
        var queryItems: [URLQueryItem] = []
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        if let platform = platform {
            queryItems.append(URLQueryItem(name: "platform", value: platform))
        }
        if let ifa = ifa {
            queryItems.append(URLQueryItem(name: "ifa", value: ifa))
        }
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        let url = urlComponents.url!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = JSONDecoder()
        return try decoder.decode(MissionResponse.self, from: data)
    }
    
    func getBanner(userId: String, placementId: String, platform: String) async throws -> BannerResponse {
        var urlComponents = URLComponents(string: "\(baseURL)\(ApiConfig.Endpoints.getBanner)")!
        urlComponents.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "placementId", value: placementId),
            URLQueryItem(name: "platform", value: platform)
        ]
        
        let url = urlComponents.url!
        let urlRequest = createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, _) = try await session.data(for: urlRequest)
        let decoder = JSONDecoder()
        return try decoder.decode(BannerResponse.self, from: data)
    }
}
