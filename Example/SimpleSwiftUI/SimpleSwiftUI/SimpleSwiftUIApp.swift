import SwiftUI
import Cheq

@main
struct SimpleSwiftUIApp: App {
    init() {    
        // track launch count
        if var launchCount = Sst.dataLayer.get("launchCount") as? Int {
            launchCount += 1
            Sst.dataLayer.add(key: "launchCount", value: launchCount)
        } else {
            Sst.dataLayer.add(key: "launchCount", value: 1)
        }
        Sst.configure(Config("mobile_demo",
                             models: try! Models(Static(), CheqAdvertisingModel()),
                             debug: true))
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class Static : Model {
    override var key: String {
        "custom_static_model"
    }
    override func get(event: SstEvent, sst: Sst) async -> Any {
        return ["foo": "bar"]
    }
}
