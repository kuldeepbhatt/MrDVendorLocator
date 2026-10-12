import Foundation

@MainActor
final class VendorListViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var vendors: [Vendor] = []
    @Published var selectedVendorID: String?
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [PlaceSearchResult] = []
    @Published private(set) var isSearching = false

    var isLoading: Bool { state == .loading }

    private let loadVendors: LoadVendorsUseCase
    private let searchPlaces: SearchPlacesUseCase
    private var searchTask: Task<Void, Never>?
    private var locallyAddedVendorIDs: Set<String> = []

    init(loadVendors: LoadVendorsUseCase, searchPlaces: SearchPlacesUseCase) {
        self.loadVendors = loadVendors
        self.searchPlaces = searchPlaces
    }

    func load() async {
        guard state == .idle else { return }
        await reload()
    }

    func reload() async {
        guard state != .loading else { return }
        let favoriteOverrides = Dictionary(uniqueKeysWithValues: vendors.map { ($0.id, $0.isFavorite) })
        let localVendors = vendors.filter { locallyAddedVendorIDs.contains($0.id) }
        state = .loading
        do {
            var refreshedVendors = try await loadVendors.execute().map { vendor in
                var vendor = vendor
                vendor.isFavorite = favoriteOverrides[vendor.id] ?? vendor.isFavorite
                return vendor
            }
            let refreshedIDs = Set(refreshedVendors.map(\.id))
            refreshedVendors.append(contentsOf: localVendors.filter { !refreshedIDs.contains($0.id) })
            vendors = refreshedVendors
            if let selectedVendorID, !vendors.contains(where: { $0.id == selectedVendorID }) {
                self.selectedVendorID = nil
            }
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleFavorite(for vendorID: String) {
        guard let index = vendors.firstIndex(where: { $0.id == vendorID }) else { return }
        vendors[index].isFavorite.toggle()
    }

    func select(_ vendorID: String) {
        selectedVendorID = vendorID
    }

    func search() {
        searchTask?.cancel()
        let query = searchQuery
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                searchResults = try await searchPlaces.execute(query: query)
            } catch is CancellationError {
                return
            } catch {
                state = .failed("Place search failed: \(error.localizedDescription)")
            }
            isSearching = false
        }
    }

    func addPlace(_ place: PlaceSearchResult) {
        let vendor = Vendor(
            id: "place-\(place.id)",
            name: place.name,
            address: place.address,
            coordinate: place.coordinate,
            isFavorite: false,
            updatedAt: .now
        )
        if !vendors.contains(where: { $0.id == vendor.id }) {
            vendors.append(vendor)
            locallyAddedVendorIDs.insert(vendor.id)
        }
        selectedVendorID = vendor.id
        searchQuery = ""
        searchResults = []
    }

    func dismissError() {
        state = vendors.isEmpty ? .idle : .loaded
    }
}
