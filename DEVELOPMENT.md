### Development

1. Install Xcode 16: https://developer.apple.com/xcode/
2. Open Package.swift in Xcode
3. Run Tests for cheq-sst-swift

### Building

1. Requires iPhone 16 Simulator
2. Run `build.sh`

### Sample App

1. Ensure you do not have the local `Cheq` package opened in Xcode
2. Open `Example/SimpleSwiftUI/SimpleSwiftUI.xcodeproj`
3. Deploy to simulator or device

### Release

1. `git flow release start <VERSION>`
2. Update `Sources/Cheq/Info.swift` library_version `static let library_version = "<VERSION>"` and commit
3. `git flow release finish`
4. `./push-github.sh`
5. Verify documentation was published to https://cheq-ai.github.io/cheq-sst-swift/
