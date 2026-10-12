protocol PlaceSearching: Sendable {
    func search(query: String) async throws -> [PlaceSearchResult]
}

struct PlaceSearchResult: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
}

