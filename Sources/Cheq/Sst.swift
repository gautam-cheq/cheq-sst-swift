import Foundation
import os
import WebKit

/// Cheq Server-Side Tagging framework
///
/// Provides functionality for configuring Sst and tracking events
public struct Sst {
    static internal let log = Logger(subsystem: "Cheq", category: "Sst")
    static internal let baseParams: [String : String] = ["sstOrigin": "mobile", "sstVersion": "1.0.0"]
    static internal var uaTask:Task<Void, Never> {
        let task = Task {
            let userAgent = await MainActor.run {
                let webView = WKWebView()
                return webView.value(forKey: "userAgent") as? String
            }
            Sst.instance?.userAgent = userAgent
        }
        return task
    }
    
    static internal var instance:Sst?
    public static let dataLayer = DataLayer()
    
    let config:Config
    var userAgent: String?
    
    init(config: Config) {
        self.config = config
    }
    
    /// Configures Sst
    /// - Parameter config: The configuration object
    public static func configure(_ config: Config) {
        guard URL(string: "https://\(config.domain)/pc/\(config.clientName)/sst") != nil else {
            log.error("Cheq Sst not configured, invalid domain or client")
            return
        }
        instance = Sst(config: config)
        log.info("Cheq Sst configured")
    }
    
    /// Tracks an event
    /// - Parameter event: The event to be tracked
    public static func trackEvent(_ event: SstEvent) async {
        let _ = await _trackEvent(event)
    }
    
    /// Retrieves the stored Cheq Uuid
    public static func getCheqUuid() -> String? {
        return HTTP.getUUID()
    }
    
    /// Clears the stored Cheq Uuid
    public static func clearCheqUuid() {
        HTTP.clearUUID()
    }

    static func _trackEvent(_ event: SstEvent) async -> TrackEventResult? {
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return nil
        }
        if (instance.userAgent == nil) {
            await Sst.uaTask.value
        }
        var event_data = event.data
        if !event_data.keys.contains("__timestamp") {
            let timestamp = Int(instance.config.dateProvider.now().timeIntervalSince1970 * 1000)
            event_data["__timestamp"] = timestamp
        }
        
        let screenInfo = Info.getScreenInfo()
        let sstData: [String: Any] = [
            "settings": Settings(publishPath: instance.config.publishPath, nexusHost: instance.config.nexusHost),
            "dataLayer": [
                "__mobileData": await instance.config.models.collect(event: event, sst: instance),
                instance.config.dataLayerName: dataLayer.all()
            ],
            "events": [Event(name: event.name, data: event_data)],
            "virtualBrowser": VirtualBrowser(height: screenInfo.height,
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
                                                 url: instance.getURL(params: event.parameters),
                                                 jsonString: jsonString!,
                                                 debug: instance.config.debug)
        return TrackEventResult(statusCode: statusCode, requestBody: jsonString!)
    }
    
    static func getInstance() -> Sst {
        guard let instance = instance else {
            fatalError("Not configured, must call configure first")
        }
        return instance
    }
    
    func getParams(params:[String: String]) -> [URLQueryItem] {
        let combinedParams = params.merging(Sst.baseParams) { (_, new) in new }
        return combinedParams.keys.sorted().map { key in
            URLQueryItem(name: key, value: combinedParams[key])
        }
    }
    
    func getURL(params:[String: String] = [:]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = config.domain
        components.path = "/pc/\(config.clientName)/sst"
        components.queryItems = getParams(params: params)
        return components.url!
    }
}
