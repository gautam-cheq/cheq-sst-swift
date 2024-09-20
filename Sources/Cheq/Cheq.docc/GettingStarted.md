# Getting Started with CHEQ Server-Side Tagging (SST)

### Configure SST

Provide client name

```swift
import Cheq

await Sst.configure(Config("client_name") 
```

### Track Event

Provide a name and optional data

```swift
import Cheq

await Sst.trackEvent(Event("screen_view", data: ["screen_name": "Home"]) 
```
