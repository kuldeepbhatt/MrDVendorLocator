import Foundation
import XCTest
@testable import MrDVendorLocator

final class DefaultVendorRepositoryTests: XCTestCase {
    func testVendorsDecodesRESTPayloadIntoDomainModel() async throws {
        let payload = #"""
        [{
          "id":"ven-101",
          "name":"Test Kitchen",
          "address":"1 Test Street",
          "coordinate":{"latitude":-33.92,"longitude":18.42},
          "isFavorite":true,
          "updatedAt":"2025-06-01T12:00:00Z"
        }]
        """#.data(using: .utf8)!
        let repository = DefaultVendorRepository(api: VendorAPIStub(data: payload))

        let vendors = try await repository.vendors()

        XCTAssertEqual(vendors.count, 1)
        XCTAssertEqual(vendors[0].id, "ven-101")
        XCTAssertEqual(vendors[0].coordinate, Coordinate(latitude: -33.92, longitude: 18.42))
        XCTAssertTrue(vendors[0].isFavorite)
    }

    func testVendorsRejectsMalformedPayload() async {
        let repository = DefaultVendorRepository(api: VendorAPIStub(data: Data("not-json".utf8)))

        do {
            _ = try await repository.vendors()
            XCTFail("Expected malformed JSON to throw")
        } catch {
            XCTAssertTrue(error is DecodingError)
        }
    }
}

private struct VendorAPIStub: VendorAPI {
    let data: Data
    func fetchVendors() async throws -> Data { data }
}

@MainActor
final class VendorListViewModelRefreshTests: XCTestCase {
    func testReloadPreservesFavoriteOverridesAndLocallyAddedPlaces() async {
        let remoteVendor = Vendor(
            id: "ven-101",
            name: "Test Kitchen",
            address: "1 Test Street",
            coordinate: .init(latitude: -33.92, longitude: 18.42),
            isFavorite: false,
            updatedAt: .distantPast
        )
        let viewModel = VendorListViewModel(
            loadVendors: LoadVendorsUseCaseStub(vendors: [remoteVendor]),
            searchPlaces: SearchPlacesUseCaseStub()
        )

        await viewModel.load()
        viewModel.toggleFavorite(for: remoteVendor.id)
        viewModel.addPlace(.init(
            id: "local-1",
            name: "Local Place",
            address: "2 Local Street",
            coordinate: .init(latitude: -33.90, longitude: 18.40)
        ))

        await viewModel.reload()

        XCTAssertEqual(viewModel.vendors.count, 2)
        XCTAssertTrue(viewModel.vendors.first(where: { $0.id == remoteVendor.id })?.isFavorite == true)
        XCTAssertTrue(viewModel.vendors.contains(where: { $0.id == "place-local-1" }))
        XCTAssertEqual(viewModel.selectedVendorID, "place-local-1")
    }

    func testLoadFailureAndDismissReturnToIdle() async {
        let viewModel = VendorListViewModel(
            loadVendors: FailingLoadVendorsUseCase(),
            searchPlaces: SearchPlacesUseCaseStub()
        )

        await viewModel.load()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertFalse(message.isEmpty)

        viewModel.dismissError()
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testReloadClearsSelectionWhenRemoteVendorDisappears() async {
        let loader = SequencedLoadVendorsUseCase(responses: [[makeVendor(id: "one")], []])
        let viewModel = VendorListViewModel(loadVendors: loader, searchPlaces: SearchPlacesUseCaseStub())

        await viewModel.load()
        viewModel.select("one")
        await viewModel.reload()

        XCTAssertNil(viewModel.selectedVendorID)
        XCTAssertTrue(viewModel.vendors.isEmpty)
    }

    func testAddPlaceDoesNotCreateDuplicates() async {
        let viewModel = VendorListViewModel(
            loadVendors: LoadVendorsUseCaseStub(vendors: []),
            searchPlaces: SearchPlacesUseCaseStub()
        )
        let place = PlaceSearchResult(
            id: "same",
            name: "Same Place",
            address: "Same Address",
            coordinate: .init(latitude: 1, longitude: 2)
        )

        await viewModel.load()
        viewModel.addPlace(place)
        viewModel.addPlace(place)

        XCTAssertEqual(viewModel.vendors.count, 1)
        XCTAssertEqual(viewModel.selectedVendorID, "place-same")
    }

    func testSearchDebouncesRapidQueriesAndPublishesLatestResults() async throws {
        let result = PlaceSearchResult(
            id: "cape",
            name: "Cape Town",
            address: "South Africa",
            coordinate: .init(latitude: -33.92, longitude: 18.42)
        )
        let search = RecordingSearchPlacesUseCase(results: [result])
        let viewModel = VendorListViewModel(
            loadVendors: LoadVendorsUseCaseStub(vendors: []),
            searchPlaces: search
        )

        viewModel.searchQuery = "Ca"
        viewModel.search()
        viewModel.searchQuery = "Cape"
        viewModel.search()
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(search.receivedQueries, ["Cape"])
        XCTAssertEqual(viewModel.searchResults, [result])
        XCTAssertFalse(viewModel.isSearching)
    }

    func testShortSearchClearsExistingResults() async throws {
        let result = PlaceSearchResult(
            id: "cape",
            name: "Cape Town",
            address: "South Africa",
            coordinate: .init(latitude: -33.92, longitude: 18.42)
        )
        let search = RecordingSearchPlacesUseCase(results: [result])
        let viewModel = VendorListViewModel(
            loadVendors: LoadVendorsUseCaseStub(vendors: []),
            searchPlaces: search
        )
        viewModel.searchQuery = "Cape"
        viewModel.search()
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertFalse(viewModel.searchResults.isEmpty)

        viewModel.searchQuery = "C"
        viewModel.search()

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    private func makeVendor(id: String) -> Vendor {
        Vendor(
            id: id,
            name: id,
            address: "Address",
            coordinate: .init(latitude: 0, longitude: 0),
            isFavorite: false,
            updatedAt: .distantPast
        )
    }
}

private struct LoadVendorsUseCaseStub: LoadVendorsUseCase {
    let vendors: [Vendor]
    func execute() async throws -> [Vendor] { vendors }
}

private struct SearchPlacesUseCaseStub: SearchPlacesUseCase {
    func execute(query: String) async throws -> [PlaceSearchResult] { [] }
}

private final class RecordingSearchPlacesUseCase: SearchPlacesUseCase, @unchecked Sendable {
    let results: [PlaceSearchResult]
    private(set) var receivedQueries: [String] = []

    init(results: [PlaceSearchResult]) { self.results = results }

    func execute(query: String) async throws -> [PlaceSearchResult] {
        receivedQueries.append(query)
        return results
    }
}

private enum RefreshTestError: Error { case failed }

private struct FailingLoadVendorsUseCase: LoadVendorsUseCase {
    func execute() async throws -> [Vendor] { throw RefreshTestError.failed }
}

private final class SequencedLoadVendorsUseCase: LoadVendorsUseCase, @unchecked Sendable {
    private var responses: [[Vendor]]

    init(responses: [[Vendor]]) { self.responses = responses }

    func execute() async throws -> [Vendor] {
        guard !responses.isEmpty else { return [] }
        return responses.removeFirst()
    }
}

final class UseCaseTests: XCTestCase {
    func testLoadVendorsSortsNamesCaseInsensitively() async throws {
        let repository = VendorRepositoryStub(vendors: [
            makeVendor(id: "2", name: "zebra"),
            makeVendor(id: "1", name: "Apple")
        ])

        let vendors = try await DefaultLoadVendorsUseCase(repository: repository).execute()

        XCTAssertEqual(vendors.map(\.name), ["Apple", "zebra"])
    }

    func testSearchNormalizesQueryBeforeCallingService() async throws {
        let service = PlaceSearchingSpy()

        _ = try await DefaultSearchPlacesUseCase(service: service).execute(query: "  Cape Town  ")

        XCTAssertEqual(service.receivedQueries, ["Cape Town"])
    }

    func testSearchRejectsShortQueryWithoutCallingService() async throws {
        let service = PlaceSearchingSpy()

        let results = try await DefaultSearchPlacesUseCase(service: service).execute(query: " a ")

        XCTAssertTrue(results.isEmpty)
        XCTAssertTrue(service.receivedQueries.isEmpty)
    }

    private func makeVendor(id: String, name: String) -> Vendor {
        Vendor(
            id: id,
            name: name,
            address: "Address",
            coordinate: .init(latitude: 0, longitude: 0),
            isFavorite: false,
            updatedAt: .distantPast
        )
    }
}

private struct VendorRepositoryStub: VendorRepository {
    let vendors: [Vendor]
    func vendors() async throws -> [Vendor] { vendors }
}

private final class PlaceSearchingSpy: PlaceSearching, @unchecked Sendable {
    private(set) var receivedQueries: [String] = []

    func search(query: String) async throws -> [PlaceSearchResult] {
        receivedQueries.append(query)
        return []
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testSaveTrimsAndPersistsToken() {
        let store = TokenStoreSpy()
        let viewModel = SettingsViewModel(tokenStore: store)
        viewModel.token = "  secret-token  "

        viewModel.save()

        XCTAssertEqual(store.savedToken, "secret-token")
        XCTAssertEqual(viewModel.token, "secret-token")
        XCTAssertTrue(viewModel.hasSavedToken)
        XCTAssertEqual(viewModel.statusMessage, "Token saved in Keychain.")
    }

    func testReadAndClearReflectTokenStore() {
        let store = TokenStoreSpy(token: "stored-token")
        let viewModel = SettingsViewModel(tokenStore: store)

        viewModel.read()
        XCTAssertEqual(viewModel.token, "stored-token")
        XCTAssertTrue(viewModel.hasSavedToken)

        viewModel.clear()
        XCTAssertEqual(viewModel.token, "")
        XCTAssertFalse(viewModel.hasSavedToken)
        XCTAssertTrue(store.didClear)
    }

    func testSaveRejectsWhitespaceOnlyToken() {
        let store = TokenStoreSpy()
        let viewModel = SettingsViewModel(tokenStore: store)
        viewModel.token = "   "

        viewModel.save()

        XCTAssertNil(store.savedToken)
        XCTAssertEqual(viewModel.statusMessage, "Enter a token before saving.")
    }
}

private final class TokenStoreSpy: TokenStoring, @unchecked Sendable {
    var token: String?
    var savedToken: String?
    var didClear = false

    init(token: String? = nil) { self.token = token }

    func save(_ token: String) throws {
        self.token = token
        savedToken = token
    }

    func read() throws -> String? { token }

    func clear() throws {
        token = nil
        didClear = true
    }
}

final class KeychainTokenStoreTests: XCTestCase {
    func testSaveUpdateReadAndClearRoundTrip() throws {
        let store = KeychainTokenStore(service: "za.co.mrd.vendorlocator.tests.\(UUID().uuidString)")
        defer { try? store.clear() }

        XCTAssertNil(try store.read())

        try store.save("first")
        XCTAssertEqual(try store.read(), "first")

        try store.save("updated")
        XCTAssertEqual(try store.read(), "updated")

        try store.clear()
        XCTAssertNil(try store.read())
    }
}

final class AuthenticatedHTTPClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testAddsBearerTokenAndReturnsSuccessfulResponseData() async throws {
        let expectedData = Data("response".utf8)
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, expectedData)
        }
        let client = AuthenticatedHTTPClient(
            session: makeSession(),
            tokenStore: TokenStoreSpy(token: "abc123")
        )

        let data = try await client.data(for: URLRequest(url: URL(string: "https://example.test/vendors")!))

        XCTAssertEqual(data, expectedData)
    }

    func testDoesNotAddAuthorizationHeaderWithoutToken() async throws {
        URLProtocolStub.requestHandler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }
        let client = AuthenticatedHTTPClient(session: makeSession(), tokenStore: TokenStoreSpy())

        _ = try await client.data(for: URLRequest(url: URL(string: "https://example.test/vendors")!))
    }

    func testThrowsServerErrorForNonSuccessStatus() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }
        let client = AuthenticatedHTTPClient(session: makeSession(), tokenStore: TokenStoreSpy())

        do {
            _ = try await client.data(for: URLRequest(url: URL(string: "https://example.test/vendors")!))
            XCTFail("Expected server error")
        } catch VendorAPIError.server(let statusCode) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }
}

private final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
