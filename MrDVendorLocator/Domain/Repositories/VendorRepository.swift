protocol VendorRepository: Sendable {
    func vendors() async throws -> [Vendor]
}

