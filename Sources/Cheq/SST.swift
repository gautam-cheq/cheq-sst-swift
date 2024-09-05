import Foundation
import os
import WebKit

public class SST {
    static internal let log = Logger(subsystem: "com.cheq", category: "SST")
    static internal let baseParams: [String : String] = ["sstOrigin": "mobile", "sstVersion": "1.0.0"]
    
    static internal var instance:SST?
    
    let config:SSTConfig
    let userAgent: String?
    
    init(config: SSTConfig, userAgent: String?) {
        self.config = config
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
    
    public static func trackEvent(_ event: TrackEvent) async {
        let _ = await _trackEvent(event)
    }
    
    public static func getUUID() -> String? {
        return HTTP.getUUID()
    }
    
    public static func clearUUID() {
        HTTP.clearUUID()
    }
    
    public enum dataLayer {
        public static func all() -> [String: Any] {
            return DataLayer.all()
        }
        
        public static func clear() {
            DataLayer.clear()
        }
        
        public static func contains(_ key:String) -> Bool {
            return DataLayer.contains(key)
        }
        
        public static func get(_ key: String) -> Any? {
            return DataLayer.get(key)
        }
        
        public static func add(key: String, value: Any) {
            DataLayer.add(key: key, value: value)
        }
        
        public static func remove(_ key: String) -> Bool {
            return DataLayer.remove(key)
        }
    }
    
    static func _trackEvent(_ event: TrackEvent) async -> TrackEventResult? {
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return nil
        }
        var event_data = event.data
        if !event_data.keys.contains("__timestamp") {
            let timestamp = Int(instance.config.dateProvider.now().timeIntervalSince1970 * 1000)
            event_data["__timestamp"] = timestamp
        }
        
        let screenInfo = Info.getScreenInfo()
        let sstData: [String: Any] = [
            "settings": SSTSettings(publishPath: instance.config.publishPath, nexusHost: instance.config.nexusHost),
            "dataLayer": [
                "__mobileData": await instance.config.models.collect(event: event, sst: instance),
                instance.config.dataLayerName: dataLayer.all()
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
                                                 debug: instance.config.debug)
        return TrackEventResult(statusCode: statusCode, requestBody: jsonString!)
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
        components.host = config.domain
        components.path = "/pc/\(config.client)/sst"
        components.queryItems = getParams(params: params)
        return components.url!
    }
}
