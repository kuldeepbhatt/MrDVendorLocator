import Foundation

protocol VendorAPI: Sendable {
    func fetchVendors() async throws -> Data
}

enum VendorAPIError: LocalizedError {
    case missingFixture
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingFixture: return "The vendor catalogue is unavailable."
        case .invalidResponse: return "The server returned an invalid response."
        case let .server(statusCode): return "The server returned error \(statusCode)."
        }
    }
}

struct BundledVendorAPI: VendorAPI {
    let bundle: Bundle

    func fetchVendors() async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            guard let url = bundle.url(forResource: "Vendors", withExtension: "json") else {
                throw VendorAPIError.missingFixture
            }
            return try Data(contentsOf: url)
        }.value
    }
}

struct HTTPVendorAPI: VendorAPI {
    let endpoint: URL
    let client: HTTPClient

    func fetchVendors() async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await client.data(for: request)
    }
}

