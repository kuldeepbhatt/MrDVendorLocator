protocol TokenStoring: Sendable {
    func save(_ token: String) throws
    func read() throws -> String?
    func clear() throws
}

