import Foundation

struct TrackEventRequest: Encodable {
    let name: String
    let timestamp: Int
    let sessionId: String
    let userId: String?
    let deviceId: String
    let advertisingId: String?
    let os: String
    let osVersion: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name
        case timestamp
        case sessionId = "session_id"
        case userId = "user_id"
        case deviceId = "device_id"
        case advertisingId = "advertising_id"
        case os
        case osVersion = "os_version"
        case parameters
    }
    
    func encode(to encoder: Encoder) throws {
        // Create a dictionary with all the fields
        var dict: [String: Any] = [
            "name": name,
            "timestamp": timestamp,
            "session_id": sessionId,
            "device_id": deviceId,
            "os": os,
            "os_version": osVersion,
            "parameters": parameters  // Keep as object, not string
        ]
        
        // Add optional fields
        if let userId = userId {
            dict["user_id"] = userId
        }
        if let advertisingId = advertisingId {
            dict["advertising_id"] = advertisingId
        }
        
        // Convert to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        
        // Encode as single value
        var container = encoder.singleValueContainer()
        try container.encode(jsonData)
    }
    
    init(name: String, timestamp: Int, sessionId: String, userId: String?, deviceId: String, advertisingId: String?, os: String, osVersion: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.userId = userId
        self.deviceId = deviceId
        self.advertisingId = advertisingId
        self.os = os
        self.osVersion = osVersion
        self.parameters = parameters ?? [:]
    }
}