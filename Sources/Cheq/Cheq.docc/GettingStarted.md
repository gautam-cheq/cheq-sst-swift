# Getting Started

### Configure SST

To configure SST, you initialize a new ``Config`` structure and provide your client name.

```swift
import Cheq

Sst.configure(Config("client_name")) 
```

While developing, you can enable debug to print log messages to the console that include information about the request and response from SST.
> Remember to disable this when releasing your application.

```swift
import Cheq

Sst.configure(Config("client_name", debug: true)) 
```

### Track Event

To track an event, you initialize a new ``Event`` structure and provide the event name.

```swift
import Cheq

await Sst.trackEvent(Event("launch")) 
```

To include additional data for the event, populate the data property.

```swift
import Cheq

await Sst.trackEvent(Event("screen_view", data: ["screen_name": "Home"])) 
```

### Persistent Data Layer

The SDK includes the ``DataLayer`` structure, that can be accessed on the ``Sst`` class via the ``Sst/dataLayer`` property. This data is persisted to disk and included in every request sent to SST.

```swift
import Cheq

// at app start, initialize or increment the launch count
if var launchCount = Sst.dataLayer.get("launchCount") as? Int {
    launchCount += 1
    Sst.dataLayer.add(key: "launchCount", value: launchCount)
} else {
    Sst.dataLayer.add(key: "launchCount", value: 1)
}

```

### CHEQ UUID

The CHEQ [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) is automatically generated and populated by the SST servers. This unique identifier is persisted to disk by the SDK, ensuring it is available across multiple sessions and app launches. The UUID is a critical component in identifying and tracking users or sessions, and it is included on every request to SST.

```swift
import Cheq

// retrieve CHEQ UUID
let uuid = Sst.getCheqUuid()

// clear the stored CHEQ UUID
Sst.clearCheqUuid()

```
