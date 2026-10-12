import Foundation

struct Vendor: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    var isFavorite: Bool
    let updatedAt: Date
}

struct Coordinate: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

