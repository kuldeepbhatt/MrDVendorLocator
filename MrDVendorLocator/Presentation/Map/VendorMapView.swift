import GoogleMaps
import SwiftUI

struct VendorMapView: UIViewRepresentable {
    let vendors: [Vendor]
    let selectedVendorID: String?
    let onMarkerTapped: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onMarkerTapped: onMarkerTapped) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: -33.9249, longitude: 18.4241, zoom: 11)
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.settings.compassButton = true
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.onMarkerTapped = onMarkerTapped
        let fingerprint = vendors.map { "\($0.id):\($0.coordinate.latitude):\($0.coordinate.longitude):\($0.isFavorite)" }.joined()
        if fingerprint != context.coordinator.fingerprint {
            context.coordinator.fingerprint = fingerprint
            mapView.clear()
            for vendor in vendors {
                let marker = GMSMarker(position: CLLocationCoordinate2D(
                    latitude: vendor.coordinate.latitude,
                    longitude: vendor.coordinate.longitude
                ))
                marker.title = vendor.name
                marker.snippet = vendor.address
                marker.userData = vendor.id
                marker.icon = GMSMarker.markerImage(with: vendor.isFavorite ? .systemRed : .systemOrange)
                marker.map = mapView
            }
        }

        if selectedVendorID != context.coordinator.selectedVendorID,
           let vendor = vendors.first(where: { $0.id == selectedVendorID }) {
            context.coordinator.selectedVendorID = selectedVendorID
            let camera = GMSCameraPosition(
                latitude: vendor.coordinate.latitude,
                longitude: vendor.coordinate.longitude,
                zoom: 15
            )
            mapView.animate(to: camera)
        }
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var onMarkerTapped: (String) -> Void
        var fingerprint = ""
        var selectedVendorID: String?

        init(onMarkerTapped: @escaping (String) -> Void) { self.onMarkerTapped = onMarkerTapped }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let vendorID = marker.userData as? String else { return false }
            onMarkerTapped(vendorID)
            return false
        }
    }
}
