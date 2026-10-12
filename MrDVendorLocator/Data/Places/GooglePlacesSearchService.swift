import GooglePlaces

final class GooglePlacesSearchService: PlaceSearching, @unchecked Sendable {
    private let client: GMSPlacesClient

    init(client: GMSPlacesClient = .shared()) { self.client = client }

    func search(query: String) async throws -> [PlaceSearchResult] {
        let predictions = try await predictions(for: query)
        return try await withThrowingTaskGroup(of: PlaceSearchResult?.self) { group in
            for prediction in predictions.compactMap(\.placeSuggestion).prefix(5) {
                group.addTask { [client] in
                    try await Self.details(for: prediction.placeID, client: client)
                }
            }
            var results: [PlaceSearchResult] = []
            for try await result in group {
                if let result { results.append(result) }
            }
            return results.sorted { $0.name < $1.name }
        }
    }

    private func predictions(for query: String) async throws -> [GMSAutocompleteSuggestion] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[GMSAutocompleteSuggestion], Error>) in
            let filter = GMSAutocompleteFilter()
            filter.countries = ["ZA"]
            let request = GMSAutocompleteRequest(query: query)
            request.filter = filter
            request.sessionToken = GMSAutocompleteSessionToken()
            client.fetchAutocompleteSuggestions(from: request) { predictions, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: predictions ?? []) }
            }
        }
    }

    private static func details(for placeID: String, client: GMSPlacesClient) async throws -> PlaceSearchResult? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PlaceSearchResult?, Error>) in
            let properties: [String] = [
                GMSPlaceProperty.name.rawValue,
                GMSPlaceProperty.formattedAddress.rawValue,
                GMSPlaceProperty.coordinate.rawValue,
                GMSPlaceProperty.placeID.rawValue
            ]
            let request = GMSFetchPlaceRequest(placeID: placeID, placeProperties: properties, sessionToken: nil)
            client.fetchPlace(with: request) { place, error in
                if let error { continuation.resume(throwing: error); return }
                guard let place, let name = place.name else { continuation.resume(returning: nil); return }
                continuation.resume(returning: PlaceSearchResult(
                    id: place.placeID ?? placeID,
                    name: name,
                    address: place.formattedAddress ?? "Address unavailable",
                    coordinate: Coordinate(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                ))
            }
        }
    }
}
