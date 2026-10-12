import SwiftUI

struct VendorRow: View {
    let vendor: Vendor
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(vendor.name).font(.headline).foregroundStyle(.primary)
                    Text(vendor.address).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onToggleFavorite) {
                    Image(systemName: vendor.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(vendor.isFavorite ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(vendor.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isSelected ? Color.orange.opacity(0.12) : Color.clear)
    }
}

struct VendorSelectionCard: View {
    let vendor: Vendor
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vendor.name).font(.headline)
                Text(vendor.address).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: vendor.isFavorite ? "heart.fill" : "heart")
                    .font(.title3).foregroundStyle(vendor.isFavorite ? .red : .secondary)
            }
            .accessibilityLabel(vendor.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 3)
    }
}
