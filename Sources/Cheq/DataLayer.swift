import Foundation
import os

enum DataLayer {
    static internal let log = Logger(subsystem: "com.cheq", category: "DataLayer")
    static let suiteName = "cheq.sst.datalayer"
    static let data = UserDefaults(suiteName: suiteName)
    
    static func all() -> [String: Any] {
        var result:[String: Any] = [:]
        if let data = data {
            let rawData = data.dictionaryRepresentation()
            for key in rawData.keys {
                if let existing = rawData[key] as? String,
                   let jsonData = existing.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    result[key] = json["value"]
                }
            }
        }
        return result
    }
    
    static func clear() {
        data?.removePersistentDomain(forName: suiteName)
    }
    
    static func contains(_ key:String) -> Bool {
        return data?.object(forKey: key) != nil
    }
    
    static func get(_ key: String) -> Any? {
        var result: Any? = nil
        if let data = data,
           let existing = data.string(forKey: key),
           let jsonData = existing.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            result = json["value"]
        }
        return result
    }
    
    static func add(key: String, value: Any) {
        guard let json = try? JSON.convertToJSONString(["value": value]) else {
            log.error("Failed to serialize value for key \(key, privacy: .public)")
            return
        }
        data?.set(json, forKey: key)
    }
    
    static func remove(_ key: String) -> Bool {
        guard contains(key) else {
            return false
        }
        data?.removeObject(forKey: key)
        return true
    }
}
