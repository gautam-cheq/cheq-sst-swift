import SwiftUI
import Cheq
import AppTrackingTransparency

#Preview {
    ContentView()
}

struct ContentView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                HomeView()
            }
        } else {
            NavigationView {
                HomeView()
            }
        }
    }
}

struct HomeView: View {
    @State var uuidText = Sst.getCheqUuid() ?? "N/A"
    private var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            Text("Home Screen")
                .font(.title)
                .padding()
            HStack {
                Text("CHEQ UUID: ").font(.footnote)
                TextField("UUID", text: $uuidText).font(.footnote)
            }.padding(EdgeInsets(top: 0, leading: 10, bottom: 00, trailing: 0))
            Button("Request Tracking Permission") {
                Task {
                    await ATTrackingManager.requestTrackingAuthorization()
                }
            }.padding()
            Button("Clear CHEQ UUID") {
                Sst.clearCheqUuid()
                uuidText = "N/A"
            }.padding()
            Button("Send Custom Example") {
                Task {
                    await Sst.trackEvent(Event("custom_example", data: ["string": "foobar",
                                                                           "int": 123,
                                                                           "float": 456.789,
                                                                           "boolean": true]))
                }
            }.padding()
            Button("Trigger Network Error") {
                Task {
                    // domain with expired certificate
                    Sst.configure(Config("mobile_demo",
                                         domain: "test.invalid",
                                         debug: true))
                    await Sst.trackEvent(Event("network_error"))
                    // reset to good config
                    SimpleSwiftUIApp.initializeSst()
                }
            }.padding()
            Button("Trigger TrackEvent Error") {
                Task {
                    await Sst.trackEvent(Event("custom_example", data: ["bad": BadEncodable()]))
                }
            }.padding()
            Button("Trigger DataLayer.add Error") {
                Sst.dataLayer.add(key: "bad", value: BadEncodable())
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
                await Sst.trackEvent(Event("screen_view", data: ["screen_name": "Home"]))
            }
        }
    }
}

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Login Screen")
                .font(.title)
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
                await Sst.trackEvent(Event("screen_view", data: ["screen_name": "Login"]))
            }
        }
    }
}

struct CartView: View {
    var body: some View {
        VStack {
            Text("Cart Screen")
                .font(.title)
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
                await Sst.trackEvent(Event("screen_view", data: ["screen_name": "Cart"]))
            }
        }
    }
}
