import XCTest
@testable import Cheq

final class SSTTests: XCTestCase {
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
        await SST.configure(SSTConfig(client: "di_demo", domain: "test", debug: true, dateProvider: StaticDateProvider(fixedDate: Date(timeIntervalSince1970: 1337))))
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
        guard let result = await SST.trackEvent(TrackEvent(name: eventName, data: ["customData": customData], params: ["foo":"bar", "test foo": "true&1337 baz="])) else {
            XCTFail("Failed to get valid response")
            return
        }
        let expected = "{\"dataLayer\":{\"__mobileData\":{\"app\":{\"build\":\"22720\",\"name\":\"xctest\",\"namespace\":\"com\",\"version\":\"15.4\"},\"device\":{\"architecture\":\"arm64\",\"id\":\"9D8E2C4E-46F7-4B5C-80C8-79BEFD8C37F7\",\"manufacturer\":\"Apple\",\"model\":\"iPhone15,4\",\"os\":{\"name\":\"iOS\",\"version\":\"17.2\"},\"screen\":{\"height\":852,\"orientation\":\"Unknown\",\"width\":393}},\"library\":{\"models\":{},\"name\":\"ios-swift\",\"version\":\"0.1\"}}},\"events\":[{\"data\":{\"__timestamp\":1337000,\"customData\":{\"cards\":[{\"rank\":\"ace\",\"suit\":\"spades\"},{\"rank\":\"two\",\"suit\":\"hearts\"}],\"custom_data\":{},\"data_processing_options\":[\"LDU\"],\"data_processing_options_country\":0,\"data_processing_options_state\":0,\"event_id\":\"0b11049b2-8afc-4156-9b69-342c692309210\",\"event_name\":\"PageView\",\"nillable\":null,\"nsnull\":null,\"user_data\":{\"em\":\"142d78e466cacab37c3751a6ba0d288ce40db609ce9c49617ea6b24665f1aa9c\",\"fbp\":\"fb.2.1720426909889.614851977197247472\"}}},\"name\":\"testTrackEvent\"}],\"settings\":{\"nexusHost\":\"nexus.ensighten.com\",\"publishPath\":\"sst\"},\"virtualBrowser\":{\"height\":852,\"width\":393}}"
        XCTAssertEqual(expected, result.requestBody, "invalid request body")
    }
    
    
    func testCustomModel() async throws {
        let foo = Foo()
        let models = try Models(foo)
        await SST.configure(SSTConfig(client: "di_demo", domain: "test", models: models, debug: true, dateProvider: StaticDateProvider(fixedDate: Date.init(timeIntervalSince1970: 2375623857))))
        guard let result = await SST.trackEvent(TrackEvent(name: "testCustomModel")) else {
            XCTFail("Failed to get valid response")
            return
        }
        print(result.requestBody)
        let expected = "{\"dataLayer\":{\"__mobileData\":{\"app\":{\"build\":\"22720\",\"name\":\"xctest\",\"namespace\":\"com\",\"version\":\"15.4\"},\"device\":{\"architecture\":\"arm64\",\"id\":\"9D8E2C4E-46F7-4B5C-80C8-79BEFD8C37F7\",\"manufacturer\":\"Apple\",\"model\":\"iPhone15,4\",\"os\":{\"name\":\"iOS\",\"version\":\"17.2\"},\"screen\":{\"height\":852,\"orientation\":\"Unknown\",\"width\":393}},\"foo\":\"\",\"library\":{\"models\":{\"foo\":\"1.33.7\"},\"name\":\"ios-swift\",\"version\":\"0.1\"}}},\"events\":[{\"data\":{\"__timestamp\":2375623857000},\"name\":\"testCustomModel\"}],\"settings\":{\"nexusHost\":\"nexus.ensighten.com\",\"publishPath\":\"sst\"},\"virtualBrowser\":{\"height\":852,\"width\":393}}"
        XCTAssertEqual(expected, result.requestBody, "invalid request body")
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
            return ""
        }
    }
}
