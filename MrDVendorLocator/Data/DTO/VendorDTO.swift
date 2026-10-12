import Foundation

struct VendorDTO: Decodable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let isFavorite: Bool
    let updatedAt: Date

    func toDomain() -> Vendor {
        Vendor(
            id: id,
            name: name,
            address: address,
            coordinate: coordinate,
            isFavorite: isFavorite,
            updatedAt: updatedAt
        )
    }
}

