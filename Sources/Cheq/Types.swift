import Foundation


/// SST Event
public struct Event {
    let name: String
    let data: [String: Any]
    let parameters: [String: String]
    
    
    /// Creates an SST Event
    /// - Parameters:
    ///   - name: name of event
    ///   - data: optional event data
    ///   - parameters: optional event parameters that will be added to the URL as query parameters
    public init(_ name: String, data: [String: Any]? = [:], parameters: [String: String]? = [:]) {
        self.name = name
        self.data = data!
        self.parameters = parameters!
    }
}

struct TrackEventResult: Codable {
    let url:String
    let requestBody: String
    let statusCode: Int?
    let userAgent: String?
}


/// SST Configuration
public struct Config {
    let clientName: String
    let domain: String
    let nexusHost: String
    let publishPath: String
    let dataLayerName: String
    let virtualBrowser: VirtualBrowser
    let models: Models
    let debug: Bool
    let dateProvider: DateProvider
    let screenEnabled: Bool
    
    
    /// Creates an SST Configuration
    /// - Parameters:
    ///   - clientName: client name
    ///   - domain: optional domain, use your first-party domain, default `t.nc0.co`
    ///   - nexusHost: optional alternative domain for loading tags, default `nexus.ensighten.com`
    ///   - publishPath: optional publish path, default `sst`
    ///   - dataLayerName: optional data layer name, default `digitalData`
    ///   - virtualBrowser: optional ``VirtualBrowser``
    ///   - models: optional custom models, default ``Models/default()``
    ///   - debug: optional flag to enable debug logging, default `false`
    ///   - dateProvider: optional date provider, default ``SystemDateProvider``
    public init(_ clientName: String,
                domain: String = "t.nc0.co",
                nexusHost: String = "nexus.ensighten.com",
                publishPath: String = "sst",
                dataLayerName: String = "digitalData",
                virtualBrowser: VirtualBrowser = VirtualBrowser(),
                models: Models = try! Models.default(),
                debug: Bool = false,
                dateProvider: DateProvider = SystemDateProvider()) {
        self.clientName = clientName
        self.domain = domain
        self.nexusHost = nexusHost
        self.publishPath = publishPath
        self.dataLayerName = dataLayerName
        self.virtualBrowser = virtualBrowser
        self.models = models
        self.debug = debug
        self.dateProvider = dateProvider
        self.screenEnabled = (models.get(DeviceModel.self))?.config.screenEnabled == true
    }
}

/// SST Virtual Browser Configuration
public struct VirtualBrowser {
    let page: String?
    let userAgent: String?
    
    /// Creates an SST Virtual Browser Configuration
    /// - Parameters:
    ///   - page: The URL of the page to be loaded in the virtual browser
    ///   - userAgent: The user agent string to be used by the virtual browser
    public init(_ page:String? = nil, userAgent: String? = nil) {
        self.page = page
        self.userAgent = userAgent
    }
}

struct VirtualBrowserData: Codable {
    let height: Int?
    let width: Int?
    let timezone: String
    let language: String
    let page: String?
}

struct Settings: Codable {
    let publishPath: String
    let nexusHost: String
}

struct AppInfo: Codable {
    let namespace: String
    let name: String
    let version: String
    let build: String
}


/// SST errors
public enum SstError: Error, Equatable {
    case invalidModelKey
    case duplicateModelKey(String)
}

struct ScreenInfo: Codable {
    let orientation: String
    let height: Int
    let width: Int
}


/// Provide current Date
public protocol DateProvider {
    func now() -> Date
}


/// Returns the system provided Date()
public struct SystemDateProvider: DateProvider {
    public init() {}
    public func now() -> Date {
        return Date()
    }
}

struct StaticDateProvider: DateProvider {
    private let fixedDate: Date
    
    init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }
    
    func now() -> Date {
        return fixedDate
    }
}
