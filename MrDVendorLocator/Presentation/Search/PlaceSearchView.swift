import SwiftUI

struct PlaceSearchView: View {
    @ObservedObject var viewModel: VendorListViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search places to add", text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit(viewModel.search)
                    .onChange(of: viewModel.searchQuery) { _ in viewModel.search() }
                if viewModel.isSearching { ProgressView().controlSize(.small) }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 8)

            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { place in
                            Button { viewModel.addPlace(place) } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse").foregroundStyle(.orange)
                                    VStack(alignment: .leading) {
                                        Text(place.name).font(.subheadline.bold())
                                        Text(place.address).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill").foregroundStyle(.orange)
                                }
                                .padding(.horizontal).padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .frame(maxHeight: 180)
                .background(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .zIndex(2)
            }
        }
    }
}

