import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var revealsToken = false

    var body: some View {
        Form {
            Section("API Session") {
                HStack {
                    Group {
                        if revealsToken { TextField("Session token", text: $viewModel.token) }
                        else { SecureField("Session token", text: $viewModel.token) }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Button { revealsToken.toggle() } label: {
                        Image(systemName: revealsToken ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel(revealsToken ? "Hide token" : "Show token")
                }
                Button("Save Token", action: viewModel.save).disabled(viewModel.token.isEmpty)
                Button("Read Token", action: viewModel.read)
                Button("Clear Token", role: .destructive, action: viewModel.clear)
                    .disabled(!viewModel.hasSavedToken)
            }

            Section("Security") {
                Label("Stored in this device’s Keychain", systemImage: "lock.shield")
                Text("When the remote REST adapter is enabled, the token is sent as a Bearer authorization header.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            if let message = viewModel.statusMessage {
                Section { Text(message).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: viewModel.read)
    }
}
