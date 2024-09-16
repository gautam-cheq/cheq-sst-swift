import SwiftUI
import Cheq
import AppTrackingTransparency

#Preview {
    ContentView()
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomeView()
        }
    }
}

struct HomeView: View {
    @State var uuidText = Sst.getCheqUuid() ?? "N/A"
    private var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            Text("Home Screen")
                .font(.largeTitle)
                .padding()
            HStack {
                Text("Uuid: ").font(.footnote)
                TextField("UUID", text: $uuidText).font(.footnote)
            }.padding()
            Button("Request Tracking Permission") {
                Task {
                    await ATTrackingManager.requestTrackingAuthorization()
                }
            }.padding()
            Button("Clear Cheq Uuid") {
                Sst.clearCheqUuid()
                uuidText = "N/A"
            }.padding()
            Button("Send Custom Example") {
                Task {
                    await Sst.trackEvent(SstEvent("custom_example", data: ["string": "foobar",
                                                                           "int": 123,
                                                                           "float": 456.789,
                                                                           "boolean": true]))
                }
            }.padding()
            NavigationLink(destination: LoginView()) {
                Text("Go to Login")
            }.padding()
            NavigationLink(destination: CartView()) {
                Text("Go to Cart")
            }.padding()
        }
        .onReceive(timer) { _ in
            uuidText = Sst.getCheqUuid() ?? "N/A"
        }
        .onAppear {
            Task {
                await Sst.trackEvent(SstEvent("screen_view", data: ["screen_name": "Home"]))
            }
        }
    }
}

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Login Screen")
                .font(.largeTitle)
                .padding()
            NavigationLink(destination: HomeView()) {
                Text("Go to Home")
            }.padding()
            NavigationLink(destination: CartView()) {
                Text("Go to Cart")
            }.padding()
        }
        .onAppear {
            Task {
                await Sst.trackEvent(SstEvent("screen_view", data: ["screen_name": "Login"]))
            }
        }
    }
}

struct CartView: View {
    var body: some View {
        VStack {
            Text("Cart Screen")
                .font(.largeTitle)
                .padding()
            NavigationLink(destination: HomeView()) {
                Text("Go to Home")
            }.padding()
            NavigationLink(destination: LoginView()) {
                Text("Go to Login")
            }.padding()
        }
        .onAppear {
            Task {
                await Sst.trackEvent(SstEvent("screen_view", data: ["screen_name": "Cart"]))
            }
        }
    }
}
