import Foundation

public struct TrackEvent {
    let name: String
    let data: [String: Any]
    let params: [String: String]
    
    public init(name: String, data: [String: Any]? = [:], params: [String: String]? = [:]) {
        self.name = name
        self.data = data!
        self.params = params!
    }
}

struct TrackEventResult: Codable {
    let statusCode: Int?
    let requestBody: String
}

public struct SSTConfig {
    let client: String
    let domain: String
    let nexusHost: String
    let publishPath: String
    let dataLayerName: String
    let models: Models
    let debug: Bool
    let dateProvider: DateProvider
    
    public init(client: String,
                domain: String = "t.nc0.co",
                nexusHost: String = "nexus.ensighten.com",
                publishPath: String = "sst",
                dataLayerName: String = "digitalData",
                models: Models = try! Models(),
                debug: Bool = false,
                dateProvider: DateProvider = SystemDateProvider()) {
        self.client = client
        self.domain = domain
        self.nexusHost = nexusHost
        self.publishPath = publishPath
        self.dataLayerName = dataLayerName
        self.models = models
        self.debug = debug
        self.dateProvider = dateProvider
    }
}

struct SSTVirtualBrowser: Codable {
    let height: Int
    let width: Int
    let timezone: String
    let language: String
}

struct SSTSettings: Codable {
    let publishPath: String
    let nexusHost: String
}

struct SSTEvent {
    let name: String
    let data: [String: Any]
}

struct AppInfo: Codable {
    let namespace: String
    let name: String
    let version: String
    let build: String
}

public enum SSTError: Error {
    case invalidModelKey
    case duplicateModelKey(String)
}

struct ScreenInfo: Codable {
    let orientation: String
    let height: Int
    let width: Int
}

public protocol DateProvider {
    func now() -> Date
}

public class SystemDateProvider: DateProvider {
    public init() {}
    public func now() -> Date {
        return Date()
    }
}

class StaticDateProvider: DateProvider {
    private let fixedDate: Date
    
    init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }
    
    func now() -> Date {
        return fixedDate
    }
}
