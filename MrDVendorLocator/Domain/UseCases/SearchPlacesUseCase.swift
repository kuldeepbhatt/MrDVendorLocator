protocol SearchPlacesUseCase: Sendable {
    func execute(query: String) async throws -> [PlaceSearchResult]
}

struct DefaultSearchPlacesUseCase: SearchPlacesUseCase {
    let service: PlaceSearching

    func execute(query: String) async throws -> [PlaceSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else { return [] }
        return try await service.search(query: normalizedQuery)
    }
}

