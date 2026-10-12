import SwiftUI
import GoogleMaps
import GooglePlaces

@main
struct MrDVendorLocatorApp: App {
    private let container: AppContainer

    init() {
        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        let hasConfiguredAPIKey = !apiKey.isEmpty && apiKey != "your_key_here"

        let sdkAPIKey = hasConfiguredAPIKey ? apiKey : "LOCAL_MOCK_KEY"
        GMSServices.provideAPIKey(sdkAPIKey)
        GMSPlacesClient.provideAPIKey(sdkAPIKey)
        container = AppContainer(useLivePlaces: hasConfiguredAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
