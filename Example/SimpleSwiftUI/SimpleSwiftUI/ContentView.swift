//
//  ContentView.swift
//  SimpleSwiftUI
//
//  Created by Gautam Amin on 7/24/24.
//

import SwiftUI
import Cheq

struct ContentView: View {
    @State var uuidText = SST.getUUID() ?? "N/A"
    private var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            TextField("UUID", text: $uuidText)
                .padding()
                .onReceive(timer) { _ in
                    uuidText = SST.getUUID() ?? "N/A"
                }
            Button("Clear UUID") {
                SST.clearUUID()
                uuidText = "N/A"
            }
            Button("Cart Event") {
                Task {
                    await SST.trackEvent(eventName: "cart event", data: ["price": "99.99"])
                }
            }
            Button("Home Page") {
                Task {
                    await SST.trackEvent(eventName: "home page", data: [:])
                }
            }
            Button("Login") {
                Task {
                    await SST.trackEvent(eventName: "login", data: ["user": ["name": "Test User", "username": "test", "id": 1337]])
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
