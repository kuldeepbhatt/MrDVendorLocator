import SwiftUI

struct RootView: View {
    @StateObject private var vendorListViewModel: VendorListViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(container: AppContainer) {
        _vendorListViewModel = StateObject(wrappedValue: container.vendorListViewModel)
        _settingsViewModel = StateObject(wrappedValue: container.settingsViewModel)
    }

    var body: some View {
        TabView {
            NavigationStack {
                VendorLocatorView(viewModel: vendorListViewModel)
            }
            .tabItem { Label("Vendors", systemImage: "map") }

            NavigationStack {
                SettingsView(viewModel: settingsViewModel)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.orange)
    }
}

