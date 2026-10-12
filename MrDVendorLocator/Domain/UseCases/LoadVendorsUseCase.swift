protocol LoadVendorsUseCase: Sendable {
    func execute() async throws -> [Vendor]
}

struct DefaultLoadVendorsUseCase: LoadVendorsUseCase {
    let repository: VendorRepository

    func execute() async throws -> [Vendor] {
        try await repository.vendors().sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}

