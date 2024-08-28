import Foundation
import os
import WebKit

public class SST {
    static internal let log = Logger(subsystem: "com.cheq", category: "SST")
    static internal let baseParams: [String : String] = ["sstOrigin": "mobile", "sstVersion": "1.0.0"]
    
    static internal var instance:SST?
    
    let client:String
    let domain: String
    let nexusHost: String
    let publishPath: String
    let debug: Bool
    let models: Models
    let dateProvider: DateProvider
    let userAgent: String?
    
    init(config: SSTConfig, userAgent: String?) {
        self.client = config.client
        self.domain = config.domain
        self.nexusHost = config.nexusHost
        self.publishPath = config.publishPath
        self.debug = config.debug
        self.models = config.models
        self.dateProvider = config.dateProvider
        self.userAgent = userAgent
    }
    
    public static func configure(_ config: SSTConfig) async {
        
        guard URL(string: "https://\(config.domain)/pc/\(config.client)/sst") != nil else {
            log.error("Cheq SST not configured, invalid domain or client")
            return
        }
        
        let userAgent = await MainActor.run {
            let webView = WKWebView()
            return webView.value(forKey: "userAgent") as? String
        }
        
        instance = SST(config: config, userAgent: userAgent)
        log.info("Cheq SST configured")
    }
    
    public static func trackEvent(_ event: TrackEvent) async -> TrackEventResult? {
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return nil
        }
        var event_data = event.data
        if !event_data.keys.contains("__timestamp") {
            let timestamp = Int(instance.dateProvider.now().timeIntervalSince1970 * 1000)
            event_data["__timestamp"] = timestamp
        }
        
        let screenInfo = Info.getScreenInfo()
        let sstData: [String: Any] = [
            "settings": SSTSettings(publishPath: instance.publishPath, nexusHost: instance.nexusHost),
            "dataLayer": [
                "__mobileData": await instance.models.collect(event: event, sst: instance)
            ],
            "events": [SSTEvent(name: event.name, data: event_data)],
            "virtualBrowser": SSTVirtualBrowser(height: screenInfo.height,
                                                width: screenInfo.width,
                                                timezone: TimeZone.current.identifier,
                                                language: Locale.preferredLanguages.joined(separator: ","))
        ]
        
        var jsonString: String?
        do {
            jsonString = try JSON.convertToJSONString(sstData)
        } catch {
            log.error("Failed to convert sstData: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        let statusCode = await HTTP.sendHttpPost(userAgent: instance.userAgent,
                                                 url: instance.getURL(params: event.params),
                                                 jsonString: jsonString!,
                                                 debug: instance.debug)
        return TrackEventResult(statusCode: statusCode, requestBody: jsonString!)
    }
    
    public static func getUUID() -> String? {
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return nil
        }
        return instance.getUUIDCookie()?.value
    }
    
    public static func clearUUID() {
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return
        }
        if let uuidCookie = instance.getUUIDCookie() {
            HTTPCookieStorage.shared.deleteCookie(uuidCookie)
        }
    }
    
    static func getInstance() -> SST {
        guard let instance = instance else {
            fatalError("Not configured, must call configure first")
        }
        return instance
    }
    
    func getParams(params:[String: String]) -> [URLQueryItem] {
        let combinedParams = params.merging(SST.baseParams) { (_, new) in new }
        return combinedParams.keys.sorted().map { key in
            URLQueryItem(name: key, value: combinedParams[key])
        }
    }
    
    func getURL(params:[String: String] = [:]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.domain
        components.path = "/pc/\(client)/sst"
        components.queryItems = getParams(params: params)
        return components.url!
    }
    
    func getUUIDCookie() -> HTTPCookie? {
        if let urlCookies = HTTPCookieStorage.shared.cookies(for: getURL())  {
            for cookie in urlCookies {
                if (cookie.name == "uuid") {
                    return cookie
                }
            }
        }
        return nil
    }
}
