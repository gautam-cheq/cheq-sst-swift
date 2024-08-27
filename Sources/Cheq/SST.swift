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
    let userAgent: String?
    
    init(client: String, domain: String, nexusHost: String, publishPath: String, debug: Bool, models: Models, userAgent: String?) {
        self.client = client
        self.domain = domain
        self.nexusHost = nexusHost
        self.publishPath = publishPath
        self.debug = debug
        self.models = models
        self.userAgent = userAgent
    }
    
    public static func configure(client: String,
                                 domain: String = "t.nc0.co",
                                 nexusHost: String = "nexus.ensighten.com",
                                 publishPath: String = "sst",
                                 models: Models = try! Models(),
                                 debug: Bool = false) async {
        
        guard URL(string: "https://\(domain)/pc/\(client)/sst") != nil else {
            log.error("Cheq SST not configured, invalid domain or client")
            return
        }
        
        let userAgent = await MainActor.run {
            let webView = WKWebView()
            return webView.value(forKey: "userAgent") as! String
        }
        
        instance = SST(client: client,
                       domain: domain,
                       nexusHost: nexusHost,
                       publishPath: publishPath,
                       debug: debug,
                       models: models,
                       userAgent: userAgent)
        log.info("Cheq SST configured")
    }
    
    public static func trackEvent(name: String, data: [String: Any] = [:], params: [String: String] = [:]) async {
        let event = TrackEvent(name: name, data: data, params: params)
        guard let instance = instance else {
            log.error("Not configured, must call configure first")
            return
        }
        var event_data = data
        if !event_data.keys.contains("__timestamp") {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            event_data["__timestamp"] = timestamp
        }
        
        let screenInfo = Info.getScreenInfo()
        let sstData: [String: Any] = [
            "settings": SSTSettings(publishPath: instance.publishPath, nexusHost: instance.nexusHost),
            "dataLayer": [
                "__mobileData": await instance.models.collect(event: event, sst: instance)
            ],
            "events": [SSTEvent(name: name, data: event_data)],
            "virtualBrowser": SSTVirtualBrowser(height: screenInfo.height, width: screenInfo.width)
        ]
        
        var jsonString: String?
        do {
            jsonString = try JSON.convertToJSONString(sstData)
        } catch {
            log.error("Failed to convert sstData: \(error.localizedDescription, privacy: .public)")
            return
        }
        await HTTP.sendHttpPost(userAgent: instance.userAgent, url: instance.getURL(params: params), jsonString: jsonString!, debug: instance.debug)
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
        return combinedParams.map { URLQueryItem(name: $0.key, value: $0.value) }
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
