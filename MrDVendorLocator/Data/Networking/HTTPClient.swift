import Foundation

protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> Data
}

struct AuthenticatedHTTPClient: HTTPClient {
    let session: URLSession
    let tokenStore: TokenStoring

    func data(for request: URLRequest) async throws -> Data {
        var authenticatedRequest = request
        if let token = try tokenStore.read(), !token.isEmpty {
            authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: authenticatedRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VendorAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw VendorAPIError.server(statusCode: httpResponse.statusCode)
        }
        return data
    }
}

