import Foundation

struct AppData: Codable {
    let appKey: String
    let appName: String
    let isActive: Bool?
    let adchainHubUrl: String
    let config: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case appKey
        case appName
        case isActive
        case adchainHubUrl
        case config
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appKey = try container.decode(String.self, forKey: .appKey)
        appName = try container.decode(String.self, forKey: .appName)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        adchainHubUrl = try container.decode(String.self, forKey: .adchainHubUrl)
        
        if let configData = try? container.decode(Data.self, forKey: .config),
           let jsonObject = try? JSONSerialization.jsonObject(with: configData),
           let dict = jsonObject as? [String: Any] {
            config = dict
        } else {
            config = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appKey, forKey: .appKey)
        try container.encode(appName, forKey: .appName)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encode(adchainHubUrl, forKey: .adchainHubUrl)
        
        if let config = config {
            let jsonData = try JSONSerialization.data(withJSONObject: config)
            try container.encode(jsonData, forKey: .config)
        }
    }
}