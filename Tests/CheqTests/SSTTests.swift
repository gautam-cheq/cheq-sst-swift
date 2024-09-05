import XCTest
@testable import Cheq

final class SSTTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        SST.clearUUID()
    }
    
    func testConfigureInvalidDomain() async {
        await SST.configure(SSTConfig(client: "test", domain: "a b"))
    }
    
    func testClearUUIDWithoutConfigure() {
        SST.clearUUID()
    }
    
    func testGetUUIDWithoutConfigure() {
        let uuid = SST.getUUID()
        XCTAssertNil(uuid)
    }
    
    func testTrackEvent() async throws {
        let date = Date(timeIntervalSince1970: 1337)
        await SST.configure(SSTConfig(client: "di_demo", domain: "echo.cheqai.workers.dev", debug: true, dateProvider: StaticDateProvider(fixedDate: date)))
        let eventName = "testTrackEvent"
        let customData = CustomData(custom_data: [:],
                                    event_name: "PageView",event_id: "0b11049b2-8afc-4156-9b69-342c692309210",
                                    data_processing_options: ["LDU"],
                                    data_processing_options_country: 0,
                                    data_processing_options_state: 0,
                                    user_data: [
                                        "em": "142d78e466cacab37c3751a6ba0d288ce40db609ce9c49617ea6b24665f1aa9c",
                                        "fbp": "fb.2.1720426909889.614851977197247472"
                                    ],
                                    cards: [PlayingCard(rank: Rank.ace, suit: Suit.spades), PlayingCard(rank: Rank.two, suit: Suit.hearts)],
                                    nillable: nil,
                                    nsnull: NSNull());
        guard let result = await SST._trackEvent(TrackEvent(name: eventName, data: ["customData": customData], params: ["foo":"bar", "test foo": "true&1337 baz="])) else {
            XCTFail("Failed to get valid response")
            return
        }
        
        let requestDict = decodeJSON(result.requestBody)
        verifyRequest(requestDict, eventName: eventName, date: date)
    }
    
    
    func testCustomModel() async throws {
        let foo = Foo()
        let models = try Models(foo)
        let date = Date(timeIntervalSince1970: 2375623857)
        await SST.configure(SSTConfig(client: "di_demo", domain: "test", models: models, dateProvider: StaticDateProvider(fixedDate: date)))
        guard let result = await SST._trackEvent(TrackEvent(name: "testCustomModel")) else {
            XCTFail("Failed to get valid response")
            return
        }
        
        let requestDict = decodeJSON(result.requestBody)
        verifyRequest(requestDict, eventName: "testCustomModel", date: date)
        let fooValue = ((requestDict["dataLayer"] as! [String: Any])["__mobileData"] as! [String: Any])["foo"] as! String
        XCTAssertEqual("hello", fooValue)
        let library = ((requestDict["dataLayer"] as! [String: Any])["__mobileData"] as! [String: Any])["library"] as! [String: Any]
        let fooVersion = (library["models"] as! [String: Any])["foo"] as! String
        XCTAssertEqual(foo.version, fooVersion, "invalid model version")
        
    }
    
    func testOverwriteTimestamp() async throws {
        await SST.configure(SSTConfig(client: "test", domain: "test"))
        guard let result = await SST._trackEvent(TrackEvent(name: "testOverwriteTimestamp", data: ["__timestamp": "foo"])) else {
            XCTFail("Failed to get valid response")
            return
        }
        let requestDict = decodeJSON(result.requestBody)
        verifyRequest(requestDict, eventName: "testOverwriteTimestamp")
        let timestamp = ((requestDict["events"] as! [[String: Any]])[0]["data"] as! [String: Any])["__timestamp"] as! String
        XCTAssertEqual("foo", timestamp, "invalid overwritten timestamp")
    }
    
    func testDataLayer() async throws {
        SST.dataLayer.add(key: "card", value: PlayingCard(rank: Rank.queen, suit: Suit.hearts))
        SST.dataLayer.add(key: "optedIn", value: false)
        await SST.configure(SSTConfig(client: "test", dataLayerName: "DATA"))
        guard let result = await SST._trackEvent(TrackEvent(name: "testDataLayer", data: ["__timestamp": "foo"])) else {
            XCTFail("Failed to get valid response")
            return
        }
        let requestDict = decodeJSON(result.requestBody)
        verifyRequest(requestDict, eventName: "testDataLayer")
        let DATADict = (requestDict["dataLayer"] as! [String: Any])["DATA"] as! [String: Any]
        XCTAssertFalse(DATADict["optedIn"] as! Bool)
        print(result.requestBody)
    }
    
    func verifyRequest(_ requestDict:[String: Any], eventName: String, date: Date? = nil) {
        let dataLayer = requestDict["dataLayer"] as! [String: Any]
        XCTAssertNotNil(dataLayer, "missing dataLayer")
        let mobileData = dataLayer["__mobileData"] as! [String: Any]
        XCTAssertNotNil(mobileData, "missing dataLayer.__mobileData")
        let app = mobileData["app"] as! [String: Any]
        XCTAssertNotNil(app, "missing dataLayer.__mobileData.app")
        XCTAssertNotNil(app["build"])
        XCTAssertNotNil(app["name"])
        XCTAssertNotNil(app["namespace"])
        XCTAssertNotNil(app["version"])
        let device = mobileData["device"] as! [String: Any]
        XCTAssertNotNil(device, "missing dataLayer.__mobileData.device")
        let screen = device["screen"] as! [String: Any]
        XCTAssertNotNil(screen)
        XCTAssertNotNil(screen["orientation"])
        XCTAssertNotNil(screen["width"])
        XCTAssertNotNil(screen["height"])
        XCTAssertNotNil(device["id"])
        XCTAssertNotNil(device["manufacturer"])
        XCTAssertNotNil(device["architecture"])
        XCTAssertNotNil(device["model"])
        let os = device["os"] as! [String: Any]
        XCTAssertNotNil(os)
        XCTAssertNotNil(os["name"])
        XCTAssertNotNil(os["version"])
        let library = mobileData["library"] as! [String: Any]
        XCTAssertNotNil(library, "missing dataLayer.__mobileData.library")
        XCTAssertNotNil(library["name"])
        XCTAssertNotNil(library["version"])
        XCTAssertNotNil(library["models"])
        
        let events = requestDict["events"] as! [[String: Any]]
        XCTAssertNotNil(events, "missing events")
        XCTAssertEqual(1, events.count, "invalid event count")
        let event = events[0]
        XCTAssertEqual(eventName, event["name"] as! String, "invalid event name")
        let eventData = event["data"] as! [String: Any]
        if let date = date {
            XCTAssertEqual(Int(date.timeIntervalSince1970 * 1000), eventData["__timestamp"] as! Int, "invalid __timestamp")
        }
        
        let settings = requestDict["settings"] as! [String: Any]
        XCTAssertNotNil(settings, "missing settings")
        XCTAssertNotNil(settings["publishPath"])
        XCTAssertNotNil(settings["nexusHost"])
        
        let virtualBrowser = requestDict["virtualBrowser"] as! [String: Any]
        XCTAssertNotNil(virtualBrowser, "missing virtualBrowser")
        XCTAssertNotNil(virtualBrowser["height"])
        XCTAssertNotNil(virtualBrowser["width"])
        XCTAssertNotNil(virtualBrowser["language"])
        XCTAssertNotNil(virtualBrowser["timezone"])
    }
    
    func decodeJSON(_ result: String) -> [String: Any] {
        if let jsonData = result.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            } catch {
                XCTFail("Failed to decode JSON: \(error.localizedDescription)")
            }
        }
        XCTFail("Failed to get data")
        return [:]
    }
    
    struct CustomData {
        
        let custom_data: [String: String]
        let event_name: String
        let event_id: String
        let data_processing_options: [String]
        let data_processing_options_country: Int
        let data_processing_options_state: Int
        let user_data: [String: String]
        let cards: [PlayingCard]
        let nillable: Any?
        let nsnull: NSNull
    }
    
    enum Rank: Int {
        case two = 2
        case three, four, five, six, seven, eight, nine, ten
        case jack, queen, king, ace
    }
    
    enum Suit {
        case spades, hearts, diamonds, clubs
    }
    
    struct PlayingCard {
        let rank: Rank
        let suit: Suit
    }
    
    class Foo : Model {
        override var key: String {
            get { "foo" }
        }
        override var version: String {
            get { "1.33.7" }
        }
        override func get(event: TrackEvent, sst: SST) async -> Any {
            return "hello"
        }
    }
}
