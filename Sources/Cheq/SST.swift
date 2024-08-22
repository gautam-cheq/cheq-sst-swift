import Foundation
import UIKit
import WebKit
import os

public class SST {
    static internal var formatter:ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static internal var configured = false;
    static internal var client:String?
    static internal var domain: String?
    static internal var nexusHost: String?
    static internal var publishPath: String?
    static internal var log = Logger(subsystem: "com.cheq", category: "SST")
    
    static internal let encoder = JSONEncoder()
    static internal var url:URL?
    static internal var debug: Bool = false;
    static internal var userAgent: String?
    static internal var appInfo: AppInfo?
    static internal var detailedModel: String?
    
    // MARK: public api
    public static func configure(client: String,
                                 domain: String = "t.nc0.co",
                                 nexusHost: String = "nexus.ensighten.com",
                                 publishPath: String = "sst",
                                 debug: Bool? = false) async {
        if (!configured) {
            self.client = client
            self.domain = domain
            self.nexusHost = nexusHost
            self.publishPath = publishPath
            guard let url = URL(string: "https://\(self.domain!)/pc/\(self.client!)/sst?sstOrigin=mobile&sstVersion=1.0.0") else {
                log.error("Cheq SST not configured, invalid domain or client")
                return
            }
            self.url = url
            self.debug = debug!
            userAgent = await MainActor.run {
                let webView = WKWebView()
                return webView.value(forKey: "userAgent") as? String
            }
            appInfo = getAppInfo()
            detailedModel = getDetailedModel()
            log.info("Cheq SST configured")
            configured = true
        }
    }
    
    public static func trackEvent(eventName: String, data: [String: Any]) async {
        if (!configured) {
            log.error("Not configured, must call configure first")
            return
        }
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        var settings = SSTSettings(publishPath: self.publishPath ?? "sst", nexusHost: self.nexusHost)
        let virtualBrowser = await SSTVirtualBrowser(height: Int(UIScreen.main.bounds.height), width: Int(UIScreen.main.bounds.width))
        let mobileData: [String: Any] = ["device": gatherDeviceData(), "app": appInfo!]
        let dataLayer: [String: Any] = ["__mobileData": mobileData]
        
        let eventData: [String: Any] = ["timestamp": timestamp, "event_data": data]
        let event = SSTEvent(name: eventName, data: eventData)
        
        var sstData: [String: Any] = ["settings": settings, "dataLayer": dataLayer, "events": [event]]
        
        do {
            let jsonString = try convertToJSONString(sstData)
            await sendHttpPost(jsonString: jsonString)
        } catch {
            log.error("Failed to convert sstData: \(error.localizedDescription, privacy: .public)")
        }
        
    }
    
    public static func getUUID() -> String? {
        return getUUIDCookie()?.value
    }
    
    private static func getUUIDCookie() -> HTTPCookie? {
        if let url = url,
           let urlCookies = HTTPCookieStorage.shared.cookies(for: url)  {
            for cookie in urlCookies {
                if (cookie.name == "uuid") {
                    return cookie
                }
            }
        }
        return nil
    }
    
    public static func clearUUID() {
        if let uuidCookie = getUUIDCookie() {
            HTTPCookieStorage.shared.deleteCookie(uuidCookie)
        }
    }
    
    // MARK: device info
    
    private static func gatherDeviceData() -> [String: Any] {
        let device = UIDevice.current
        let screen = UIScreen.main
        
        var deviceInfo: [String: Any] = [
            "name": device.name,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "model": device.model,
            "localizedModel": device.localizedModel,
            "identifierForVendor": device.identifierForVendor?.uuidString ?? "N/A",
            "isMultitaskingSupported": device.isMultitaskingSupported,
            "screenInfo": getScreenInfo(),
            "detailedModel": detailedModel
        ]
        
        // Get total disk space and free disk space
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let space = attrs[.systemSize] as? Int64 ?? 0
            let freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            deviceInfo["totalDiskSpace"] = ByteCountFormatter.string(fromByteCount: space, countStyle: .file)
            deviceInfo["freeDiskSpace"] = ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
        }
        
        return deviceInfo
    }
    private static func getScreenInfo() -> [String: Any] {
        let orientation: String
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = "Portrait"
        case .faceDown:
            orientation = "Face Down"
        case .faceUp:
            orientation = "Face Up"
        case .landscapeLeft, .landscapeRight:
            orientation = "Landscape"
        case .portraitUpsideDown:
            orientation = "Portrait Upside Down"
        case .unknown:
            orientation = "Unknown"
        @unknown default:
            orientation = "Unknown"
        }
        return [
            "orientation": orientation,
            "width": Int(UIScreen.main.bounds.width),
            "height": Int(UIScreen.main.bounds.height)
        ]
    }
    
    private static func logRequest(request:URLRequest) {
        // Log Request
        log.debug("--- REQUEST ---")
        log.debug("\tURL: \(request.url?.absoluteString ?? "N/A", privacy: .public)")
        log.debug("\tMethod: \(request.httpMethod ?? "N/A", privacy: .public)")
        log.debug("\tUUID: \(SST.getUUID() ?? "N/A", privacy: .public)")
        
        // Log Request Headers
        log.debug("Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            log.debug("\t\(key, privacy: .public): \(value, privacy: .public)")
        }
        
        // Log Request Body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            log.debug("Request Body:")
            log.debug("\t\(bodyString, privacy: .public)")
        }
    }
    
    private static func logResponse(response: HTTPURLResponse, responseData: Data?) {
        // Log Response
        log.debug("--- RESPONSE ---")
        log.debug("\tStatus Code: \(response.statusCode, privacy: .public)")
        
        // Log Response Headers
        log.debug("Response Headers:")
        response.allHeaderFields.forEach { key, value in
            log.debug("\t\(key, privacy: .public): \(String(describing: value), privacy: .public)")
        }
        
        // Log Response Body
        if (response.statusCode != 204) {
            if let responseData = responseData, let responseString = String(data: responseData, encoding: .utf8) {
                log.debug("Response Body:")
                log.debug("\t\(responseString, privacy: .public)")
            }
        }
    }
    
    private static func sendHttpPost(jsonString: String) async {
        var request = URLRequest(url: url!)
        if let userAgent = userAgent {
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        if (debug) {
            logRequest(request: request)
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                log.error("Invalid response")
                return
            }
            if (debug) {
                logResponse(response: httpResponse, responseData: data)
            }
        } catch {
            log.error("Error: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private static func encodeEncodable(_ encodable: Encodable) -> Any {
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
    
    private static func convertToJSONString(_ dictionary: [String: Any]) throws -> String {
        let jsonObject = sanitizeForJSON(dictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
    
    private static func sanitizeForJSON(_ value: Any) -> Any {
        switch value {
        case let number as NSNumber:
            return number
        case let string as String:
            return string
        case let bool as Bool:
            return bool
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
    
    private static func handleMirror(_ value: Any) -> Any {
        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case .struct, .class:
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
                dict["case"] = mirror.children.first?.label ?? String(describing: value)
                if mirror.children.count == 1, let (_, associatedValue) = mirror.children.first {
                    dict["associatedValue"] = sanitizeForJSON(associatedValue)
                } else if mirror.children.count > 1 {
                    var associatedValues = [String: Any]()
                    for (label, value) in mirror.children {
                        if let label = label {
                            associatedValues[label] = sanitizeForJSON(value)
                        }
                    }
                    dict["associatedValues"] = associatedValues
                }
                return dict
            }
        default:
            return String(describing: value)
        }
    }
    
    private static func getAppInfo() -> AppInfo {
        if let infoDict = Bundle.main.infoDictionary {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
            let namespace = bundleIdentifier.components(separatedBy: ".").first ?? bundleIdentifier
            return AppInfo(namespace: namespace,
                           name: infoDict["CFBundleName"] as? String ?? "Unknown",
                           version: infoDict["CFBundleShortVersionString"] as? String ?? "Unknown",
                           build: infoDict["CFBundleVersion"] as? String ?? "Unknown")
        }
        return AppInfo(namespace: "Unknown", name: "Unknown", version: "Unknown", build: "Unknown")
    }
    
    private static func getDetailedModel() -> String {
        // Get more detailed model information
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        } else {
            var systemInfo = utsname()
            uname(&systemInfo)
            let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(cString: ptr)
                }
            }
            return modelCode
        }
    }
    
    struct SSTData {
        let settings: SSTSettings
        let dataLayer: [String: Any]
        let events: [SSTEvent]
    }
    
    struct SSTVirtualBrowser: Encodable {
        let height: Int
        let width: Int
    }
    
    struct SSTSettings: Encodable {
        let publishPath: String
        let nexusHost: String?
    }
    
    struct SSTEvent {
        let name: String
        let data: [String: Any]
    }
    
    struct AppInfo {
        let namespace: String
        let name: String
        let version: String
        let build: String
    }
}

