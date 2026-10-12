import SwiftUI

struct VendorLocatorView: View {
    @ObservedObject var viewModel: VendorListViewModel
    @State private var layout: Layout = .map

    enum Layout: String, CaseIterable, Identifiable {
        case map = "Map"
        case list = "List"
        var id: Self { self }
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle where viewModel.vendors.isEmpty,
                 .loading where viewModel.vendors.isEmpty:
                ProgressView("Finding nearby vendors...")
            case let .failed(message) where viewModel.vendors.isEmpty:
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                    Text("Couldn’t load vendors").font(.title2.bold())
                    Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Try Again") { Task { await viewModel.reload() } }
                }
                .padding()
            default:
                content
            }
        }
        .navigationTitle("Vendor Locator")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if layout == .map {
                    Button {
                        Task { await viewModel.reload() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Refresh vendors")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Layout", selection: $layout) {
                    ForEach(Layout.allCases) { layout in
                        Image(systemName: layout == .map ? "map" : "list.bullet").tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("Retry") { Task { await viewModel.reload() } }
            Button("Dismiss", role: .cancel, action: viewModel.dismissError)
        } message: {
            if case let .failed(message) = viewModel.state { Text(message) }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            PlaceSearchView(viewModel: viewModel)
            if layout == .map {
                VendorMapView(
                    vendors: viewModel.vendors,
                    selectedVendorID: viewModel.selectedVendorID,
                    onMarkerTapped: viewModel.select
                )
                .ignoresSafeArea(edges: .bottom)
            } else {
                List(viewModel.vendors) { vendor in
                    VendorRow(
                        vendor: vendor,
                        isSelected: vendor.id == viewModel.selectedVendorID,
                        onSelect: { viewModel.select(vendor.id) },
                        onToggleFavorite: { viewModel.toggleFavorite(for: vendor.id) }
                    )
                }
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            if let selected = viewModel.vendors.first(where: { $0.id == viewModel.selectedVendorID }), layout == .map {
                VendorSelectionCard(vendor: selected) {
                    viewModel.toggleFavorite(for: selected.id)
                }
                .padding()
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = viewModel.state { return !viewModel.vendors.isEmpty }; return false },
            set: { if !$0 { viewModel.dismissError() } }
        )
    }
}
