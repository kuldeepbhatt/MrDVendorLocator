# Solution and architecture

## Summary

The app uses **Clean Architecture + MVVM**, composed at one dependency-injection boundary (`AppContainer`). Dependencies point inward: Presentation depends on Domain abstractions; Data implements those abstractions; the App layer selects concrete implementations. This keeps framework-heavy Google and Security code at the edges and core behavior testable.

## Layers and patterns

- **Presentation (MVVM):** SwiftUI views are declarative and contain no data access. `VendorListViewModel` owns explicit loading/loaded/error state, selection, favorites, debounced place search, and user intents. `SettingsViewModel` coordinates token actions.
- **Domain (Use Case + Repository):** framework-free entities and small protocols represent application behavior. `LoadVendorsUseCase` sorts vendor results; `SearchPlacesUseCase` normalizes/validates queries.
- **Data (Repository + Adapter):** `DefaultVendorRepository` maps REST DTOs to domain entities. `BundledVendorAPI` is the configured local REST-shaped source. `HTTPVendorAPI` and `AuthenticatedHTTPClient` are ready for a real endpoint and attach the Keychain token as `Authorization: Bearer ...`.
- **Infrastructure adapters:** `VendorMapView` bridges `GMSMapView` through `UIViewRepresentable`; `GooglePlacesSearchService` adapts callback APIs to async/await. `KeychainTokenStore` isolates Security.framework calls.
- **Composition root / DI:** `AppContainer` creates and injects dependencies. No singleton service locator is used.

## Requirement decisions

### Data loading

The default source is bundled JSON to make the evaluation deterministic and offline-friendly. It still passes through the same async `VendorAPI` and repository seams as HTTP. A production switch only needs to inject `HTTPVendorAPI`; views and use cases do not change.

Reload shows progress, failures have retry affordances, and errors are user-readable. SwiftUI semantic colors/materials respond live to system appearance changes without caching a color scheme.

### Google Maps and Places

Both official SDKs are Swift Package Manager dependencies. Markers mirror current vendors. Selecting a list row or newly searched place updates the selected ID and animates the map camera.

The chosen single Places enhancement is **place search and add**. With a valid key, `GooglePlacesSearchService` retrieves autocomplete predictions and place details. Without a key, `MockPlaceSearchService` exercises the same boundary with Cape Town fixtures. To enable live services, configure the API key as described in README and restrict it to the bundle identifier and required APIs.

### Security

The token is a generic-password Keychain item using `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so it is neither stored in source nor synchronized to other devices. Save uses update-or-insert semantics; read and clear distinguish “not found” from genuine failures. The HTTP adapter reads it just in time for each request.

## SOLID rundown

- **Single responsibility:** views render, view models coordinate UI state, use cases execute behavior, repositories map data, adapters talk to frameworks.
- **Open/closed:** remote/cached vendor APIs and alternate Places providers can be added behind existing protocols.
- **Liskov substitution:** mock and live implementations obey the same async contracts.
- **Interface segregation:** focused `VendorAPI`, `VendorRepository`, `PlaceSearching`, `HTTPClient`, and `TokenStoring` protocols avoid “god services.”
- **Dependency inversion:** domain/presentation depend on protocols; `AppContainer` injects concrete infrastructure.

## Test strategy

The XCTest suite covers REST decoding and malformed payloads, use-case sorting and query normalization, refresh merging, view-model failure/selection behavior, duplicate place prevention, Settings token workflows, and authenticated HTTP header/status handling. Framework-owned UI rendering and the real Keychain remain integration concerns; their application logic is exercised through injected protocol test doubles.

## Pragmatic trade-offs

- Favorites are session-local because persistent favorites were not required. A persistence adapter can be introduced without changing the view.
- The bundled source prioritizes reviewer reliability; the authenticated HTTP implementation demonstrates the production path but is not selected without a supplied endpoint.
- The Places adapter limits results to five and resolves details concurrently. Production code should add quotas, analytics, and finer-grained recovery.
- No location permission is requested because the task requires vendor visualization and selection recentering, not user-location tracking.
