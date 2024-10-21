import Cheq
#if canImport(AdSupport)
import AdSupport
#endif
import AppTrackingTransparency

class CheqAdvertisingModel: Model {
    override var key: String {
        get { "advertising" }
    }
    
    override func get(event: Event, sst: Sst) async -> Any {
        var trackingAuthorized = false
        var id = "Unknown"
#if canImport(AdSupport)
        if ATTrackingManager.trackingAuthorizationStatus == .authorized {
            trackingAuthorized = true
            id = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
#endif
        return AdvertisingInfo(id: id, trackingAuthorized: trackingAuthorized)
    }
}

struct AdvertisingInfo: Encodable {
    let id: String
    let trackingAuthorized: Bool
}
