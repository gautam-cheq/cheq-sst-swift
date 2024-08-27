import SwiftUI
import Cheq

struct ContentView: View {
    @State var uuidText = SST.getUUID() ?? "N/A"
    private var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            HStack {
                Text("UUID: ").font(.footnote)
                TextField("UUID", text: $uuidText).font(.footnote)
            }.padding()
            Button("Clear UUID") {
                SST.clearUUID()
                uuidText = "N/A"
            }.padding()
            Button("Cart Event") {
                Task {
                    await SST.trackEvent(name: "cart event", 
                                         data: ["price": "99.99"])
                }
            }.padding()
            Button("Home Page") {
                Task {
                    await SST.trackEvent(name: "home page",
                                         data: ["card": PlayingCard(rank: Rank.king, suit: Suit.diamonds)],
                                         params: ["hello": "world"])
                }
            }.padding()
            Button("Login") {
                Task {
                    await SST.trackEvent(name: "login", 
                                         data: ["user": ["name": "Test User", "username": "test", "id": 1337]])
                }
            }.padding()
        }
        .padding()
        .onReceive(timer) { _ in
            uuidText = SST.getUUID() ?? "N/A"
        }
    }
}

#Preview {
    ContentView()
}
