# Getting Started with Sst

### Configure Sst

Provide client name

```swift
import Cheq

await Sst.configure(Config("client_name") 
```

### Track Event

Provide a name and optional data

```swift
import Cheq

await Sst.trackEvent(SstEvent("screen_view", data: ["screen_name": "Home"]) 
```
