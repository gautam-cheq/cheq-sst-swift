import XCTest
@testable import Cheq

final class SSTTests: XCTestCase {
    func testConfigureInvalidDomain() async {
        await SST.configure(client: "test", domain: "a b")
    }
    
    func testClearUUIDWithoutConfigure() {
        SST.clearUUID()
    }
    
    func testGetUUIDWithoutConfigure() {
        let uuid = SST.getUUID()
        XCTAssertNil(uuid)
    }
    
    func testTrackEvent() async throws {
        await SST.configure(client: "di_demo", debug: true)
        
        let model = CustomData(custom_data: [:],
                          event_name: "PageView",
                          event_id: "0b11049b2-8afc-4156-9b69-342c692309210",
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
        await SST.trackEvent(name: "testConfigure", data: ["model": model], params: ["foo":"bar", "test foo": "true&1337 baz="])
        XCTAssertNotNil(SST.getUUID())
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

    struct PlayingCard{
        let rank: Rank
        let suit: Suit
    }
}

