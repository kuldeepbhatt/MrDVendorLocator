import Foundation

struct DefaultVendorRepository: VendorRepository {
    let api: VendorAPI

    func vendors() async throws -> [Vendor] {
        let data = try await api.fetchVendors()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([VendorDTO].self, from: data).map { $0.toDomain() }
    }
}

