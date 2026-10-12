# Mr D Vendor Locator

A production-shaped SwiftUI assessment app for browsing vendors, viewing them on Google Maps, adding a place through Google Places, and managing an API session token in Keychain.

## Requirements

- Xcode 15+ (latest Xcode recommended)
- iOS 16+
- A Google Maps Platform API key with **Maps SDK for iOS** and **Places API** enabled for live maps/search

## Run locally

1. Clone the repository and open `MrDVendorLocator.xcodeproj`.
2. Copy `MrDVendorLocator/Configuration/Secrets.xcconfig.example` to `Secrets.xcconfig` in the same directory.
3. Put your restricted iOS API key in `Secrets.xcconfig`:
   `GOOGLE_MAPS_API_KEY = your_key_here`
4. `Base.xcconfig` automatically includes that local file when it exists while retaining a safe no-key default.
5. Select the `MrDVendorLocator` scheme and an iOS 16+ simulator, then Run.

Without a key, vendor browsing, list interactions, Keychain settings, and deterministic mock place search work. The Google map SDK remains integrated but Google map tiles require a valid key.

## Test

Run Product > Test in Xcode, or:

```sh
xcodebuild test \
  -project MrDVendorLocator.xcodeproj \
  -scheme MrDVendorLocator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

The first build resolves the official Google Maps and Google Places Swift packages.

## Demo flow

1. Show loading, pull-to-refresh, and the map/list segmented control.
2. Select a vendor in the list, switch to the map, and show recentering.
3. Search for a place (for example, “Waterfront”) and add it as a vendor/marker.
4. Toggle favorite status from the list or map selection card.
5. Save, read, and clear a token in Settings.
6. Walk through the Domain, Data, Presentation, and App composition folders.

See [SOLUTION.md](SOLUTION.md) for the architecture and trade-offs.

## Video Recording :
https://www.loom.com/share/dbf120b73a5a4fca91f434fc6116808b
