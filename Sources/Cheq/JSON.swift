import Foundation

enum JSON {
    static internal var encoder:JSONEncoder {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return encoder
    }
    
    static internal var formatter:ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
    
    static func convertToJSONString(_ dictionary: [String: Any]) throws -> String {
        let jsonObject = try sanitizeForJSON(dictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .sortedKeys)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
    
    static internal func encodeEncodable(_ encodable: Encodable) throws -> Any {
        let data = try encoder.encode(encodable)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try sanitizeForJSON(jsonObject)
    }
    
    static internal func sanitizeForJSON(_ value: Any) throws -> Any {
        let valueType = type(of: value)
        if valueType == Bool.self {
            return value as! Bool
        }
        
        switch value {
        case let number as NSNumber:
            let doubleVal = number.doubleValue
            if doubleVal.isNaN {
                return "NaN"
            } else if doubleVal.isInfinite && doubleVal < 0 {
                return "-Infinity"
            } else if doubleVal.isInfinite {
                return "Infinity"
            }
            return number
        case let string as String:
            return string
        case let array as [Any]:
            return try array.map { try sanitizeForJSON($0) }
        case let dictionary as [String: Any]:
            return try dictionary.mapValues { try sanitizeForJSON($0) }
        case let date as Date:
            return formatter.string(from: date)
        case let data as Data:
            return data.base64EncodedString()
        case let encodable as Encodable:
            return try encodeEncodable(encodable)
        case is NSNull:
            return NSNull()
        default:
            return try handleMirror(value)
        }
    }
    
    static internal func handleMirror(_ value: Any) throws -> Any {
        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case.optional:
            if mirror.children.isEmpty {
                return NSNull()
            } else {
                return try getProperties(Mirror(reflecting: mirror.children.first!.value))
            }
        case .struct, .class, .tuple:
            return try getProperties(mirror)
        case .enum:
            if mirror.children.isEmpty {
                // For enums without associated values
                return String(describing: value)
            } else {
                // For enums with associated values
                var dict = [String: Any]()
                let key = mirror.children.first?.label ?? String(describing: value)
                let (_, associatedValue) = mirror.children.first!
                dict[key] = try sanitizeForJSON(associatedValue)
                return dict
            }
        default:
            return String(describing: value)
        }
    }
    
    static internal func getProperties(_ mirror:Mirror) throws -> [String: Any] {
        var dict = [String: Any]()
        var vMirror: Mirror? = mirror
        while let currentMirror = vMirror {
            for (label, value) in currentMirror.children {
                if let label = label {
                    dict[label] = try sanitizeForJSON(value)
                }
            }
            vMirror = currentMirror.superclassMirror
        }
        return dict
    }
}
