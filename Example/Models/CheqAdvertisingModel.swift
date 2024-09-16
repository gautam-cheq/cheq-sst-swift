import Cheq
import AdSupport
import AppTrackingTransparency

class CheqAdvertisingModel: Model {
    override var key: String {
        get { "advertising" }
    }
    
    override func get(event: SstEvent, sst: Sst) async -> Any {
        var trackingAuthorized = false
        var id = "Unknown"
        if ATTrackingManager.trackingAuthorizationStatus == .authorized {
            trackingAuthorized = true
            id = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
        return AdvertisingInfo(id: id, trackingAuthorized: trackingAuthorized)
    }
}

struct AdvertisingInfo: Encodable {
    let id: String
    let trackingAuthorized: Bool
}
