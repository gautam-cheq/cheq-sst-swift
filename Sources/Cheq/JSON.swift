import Foundation

enum JSON {
    static internal var formatter:ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
    
    static func convertToJSONString(_ dictionary: [String: Any]) throws -> String {
        let jsonObject = sanitizeForJSON(dictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
    
    static internal func encodeEncodable(_ encodable: Encodable) -> Any {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(encodable)
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return sanitizeForJSON(jsonObject)
            } else {
                return "{}"
            }
        } catch {
            return "{}"
        }
    }
    
    static internal func sanitizeForJSON(_ value: Any) -> Any {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            return number
        case let string as String:
            return string
        case let array as [Any]:
            return array.map { sanitizeForJSON($0) }
        case let dictionary as [String: Any]:
            return dictionary.mapValues { sanitizeForJSON($0) }
        case let date as Date:
            return formatter.string(from: date)
        case let data as Data:
            return data.base64EncodedString()
        case let encodable as Encodable:
            return encodeEncodable(encodable)
        case is NSNull:
            return NSNull()
        default:
            return handleMirror(value)
        }
    }
    
    static internal func handleMirror(_ value: Any) -> Any {
        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case.optional:
            return NSNull()
        case .struct, .class, .tuple:
            var dict = [String: Any]()
            for (label, value) in mirror.children {
                if let label = label {
                    dict[label] = sanitizeForJSON(value)
                }
            }
            return dict
        case .enum:
            if mirror.children.isEmpty {
                // For enums without associated values
                return String(describing: value)
            } else {
                // For enums with associated values
                var dict = [String: Any]()
                let key = mirror.children.first?.label ?? String(describing: value)
                let (_, associatedValue) = mirror.children.first!
                dict[key] = sanitizeForJSON(associatedValue)
                return dict
            }
        default:
            return String(describing: value)
        }
    }
}
