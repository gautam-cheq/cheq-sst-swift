import XCTest
@testable import Cheq

final class SSTTests: XCTestCase {
    func testConfigure() async throws {
        await SST.configure(client: "di_demo", domain: "pulse-prod.data.ensighten.com", nexusHost: "nexus.ensighten.com", publishPath: "swift-test", debug: true)
        
        let model = Model(custom_data: [:],
                          event_name: "PageView",
                          event_id: "0b11049b2-8afc-4156-9b69-342c692309210",
                          data_processing_options: ["LDU"],
                          data_processing_options_country: 0,
                          data_processing_options_state: 0,
                          user_data: [
                              "em": "142d78e466cacab37c3751a6ba0d288ce40db609ce9c49617ea6b24665f1aa9c",
                              "fbp": "fb.2.1720426909889.614851977197247472"
                          ],
                          cards: [PlayingCard(rank: Rank.ace, suit: Suit.spades), PlayingCard(rank: Rank.two, suit: Suit.hearts)]);
        await SST.trackEvent(eventName: "testConfigure", data: ["model": model])
    }
}

struct Model {
    
    let custom_data: [String: String]
    let event_name: String
    let event_id: String
    let data_processing_options: [String]
    let data_processing_options_country: Int
    let data_processing_options_state: Int
    let user_data: [String: String]
    let cards: [PlayingCard]
}

public enum Rank: Int {
    case two = 2
    case three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
}

public enum Suit {
    case spades, hearts, diamonds, clubs
}

public struct PlayingCard{
    let rank: Rank
    let suit: Suit
}

