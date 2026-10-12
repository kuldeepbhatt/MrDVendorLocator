import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var token = ""
    @Published private(set) var statusMessage: String?
    @Published private(set) var hasSavedToken = false

    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) { self.tokenStore = tokenStore }

    func read() {
        do {
            token = try tokenStore.read() ?? ""
            hasSavedToken = !token.isEmpty
            statusMessage = hasSavedToken ? "Token loaded securely." : "No token is saved."
        } catch { statusMessage = error.localizedDescription }
    }

    func save() {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { statusMessage = "Enter a token before saving."; return }
        do {
            try tokenStore.save(trimmed)
            token = trimmed
            hasSavedToken = true
            statusMessage = "Token saved in Keychain."
        } catch { statusMessage = error.localizedDescription }
    }

    func clear() {
        do {
            try tokenStore.clear()
            token = ""
            hasSavedToken = false
            statusMessage = "Token removed from Keychain."
        } catch { statusMessage = error.localizedDescription }
    }
}

