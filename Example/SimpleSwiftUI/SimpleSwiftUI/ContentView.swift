import SwiftUI
import Cheq
import AppTrackingTransparency

struct ContentView: View {
    @State var uuidText = SST.getUUID() ?? "N/A"
    private var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            Button("Request Tracking Permission") {
                Task {
                    await ATTrackingManager.requestTrackingAuthorization()
                }
            }.padding()
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
                    await SST.trackEvent(TrackEvent(name: "cart event",
                                         data: ["price": "99.99"]))
                }
            }.padding()
            Button("Home Page") {
                Task {
                    await SST.trackEvent(TrackEvent(name: "home page",
                                         data: ["card": PlayingCard(rank: Rank.king, suit: Suit.diamonds)],
                                         params: ["hello": "world"]))
                }
            }.padding()
            Button("Login") {
                Task {
                    await SST.trackEvent(TrackEvent(name: "login",
                                         data: ["user": ["name": "Test User", "username": "test", "id": 1337]]))
                }
            }.padding()
            Button("Clear URLSession Cookies") {
                Task {
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        for cookie in cookies {
                            HTTPCookieStorage.shared.deleteCookie(cookie)
                        }
                    }
                    
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
