import Foundation

@MainActor
final class AppContainer {
    let vendorListViewModel: VendorListViewModel
    let settingsViewModel: SettingsViewModel

    init(useLivePlaces: Bool) {
        let tokenStore = KeychainTokenStore(service: "za.co.mrd.vendorlocator")
        let vendorAPI = BundledVendorAPI(bundle: .main)
        let repository = DefaultVendorRepository(api: vendorAPI)
        let placesService: PlaceSearching = useLivePlaces
            ? GooglePlacesSearchService()
            : MockPlaceSearchService()

        vendorListViewModel = VendorListViewModel(
            loadVendors: DefaultLoadVendorsUseCase(repository: repository),
            searchPlaces: DefaultSearchPlacesUseCase(service: placesService)
        )
        settingsViewModel = SettingsViewModel(tokenStore: tokenStore)
    }
}
