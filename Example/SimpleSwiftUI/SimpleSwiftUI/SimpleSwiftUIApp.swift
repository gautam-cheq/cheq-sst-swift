import SwiftUI
import Cheq

@main
struct SimpleSwiftUIApp: App {
    init() {
        Task {
            // increment launch count
            if var launchCount = SST.dataLayer.get("launchCount") as? Int {
                launchCount += 1
                SST.dataLayer.add(key: "launchCount", value: launchCount)
            } else {
                SST.dataLayer.add(key: "launchCount", value: 1)
            }
            await SST.configure(SSTConfig(client: "di_demo",
                                publishPath: "sst",
                                models: try! Models(Static(), CheqAdvertisingModel()),
                                debug: true))
            await SST.trackEvent(TrackEvent(name: "launch",
                                 data: ["card": PlayingCard(rank: Rank.ace, suit: Suit.spades), "now": Date()]))
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class Static : Model {
    var card: PlayingCard?
    
    override var key: String {
        "static"
    }
    override func get(event: TrackEvent, sst: SST) async -> Any {
        if card == nil {
            card = PlayingCard(rank: Rank.eight, suit: Suit.diamonds)
        }
        return card!
    }
}

public enum Rank: Int {
    case two = 2
    case three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
}

public enum Suit: String {
    case spades, hearts, diamonds, clubs
}

public struct PlayingCard {
    let rank: Rank
    let suit: Suit
}
