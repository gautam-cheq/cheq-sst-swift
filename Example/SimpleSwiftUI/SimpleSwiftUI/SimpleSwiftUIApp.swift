//
//  SimpleSwiftUIApp.swift
//  SimpleSwiftUI
//
//  Created by Gautam Amin on 7/24/24.
//

import SwiftUI
import Cheq

@main
struct SimpleSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().task {
                await SST.configure(client: "di_demo", publishPath: "sst", debug: true)
                await SST.trackEvent(eventName: "launch", data: ["hello": "world", "card": PlayingCard(rank: Rank.ace, suit: Suit.spades), "date": Date()])
            }
        }
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
