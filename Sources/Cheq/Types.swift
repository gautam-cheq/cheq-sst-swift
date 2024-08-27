public struct TrackEvent {
    let name: String
    let data: [String: Any]
    let params: [String: String]
    
    init(name: String, data: [String: Any]? = [:], params: [String: String]? = [:]) {
        self.name = name
        self.data = data!
        self.params = params!
    }
}

struct SSTVirtualBrowser: Encodable {
    let height: Int
    let width: Int
}

struct SSTSettings: Encodable {
    let publishPath: String
    let nexusHost: String
}

struct SSTEvent {
    let name: String
    let data: [String: Any]
}

struct AppInfo: Encodable {
    let namespace: String
    let name: String
    let version: String
    let build: String
}

public enum SSTError: Error {
    case invalidModelKey
    case duplicateModelKey(String)
}

struct ScreenInfo: Encodable {
    let orientation: String
    let height: Int
    let width: Int
}
