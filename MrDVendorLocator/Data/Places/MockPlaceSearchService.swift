import Foundation

struct MockPlaceSearchService: PlaceSearching {
    private let places = [
        PlaceSearchResult(id: "mock-1", name: "V&A Waterfront", address: "19 Dock Rd, Cape Town, 8001", coordinate: .init(latitude: -33.9036, longitude: 18.4207)),
        PlaceSearchResult(id: "mock-2", name: "Canal Walk", address: "490 Century Blvd, Cape Town, 7441", coordinate: .init(latitude: -33.8931, longitude: 18.5112)),
        PlaceSearchResult(id: "mock-3", name: "Cavendish Square", address: "1 Dreyer St, Claremont, Cape Town, 7708", coordinate: .init(latitude: -33.9790, longitude: 18.4636))
    ]

    func search(query: String) async throws -> [PlaceSearchResult] {
        try await Task.sleep(for: .milliseconds(250))
        let matches = places.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.address.localizedCaseInsensitiveContains(query)
        }
        return matches.isEmpty ? Array(places.prefix(2)) : matches
    }
}

