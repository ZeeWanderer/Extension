//
//  RouterMacroUsageTests.swift
//
//
//  Created by zeewanderer on 03.02.2026.
//

import XCTest
import SwiftUI
import SwiftUIExtension
import MacrosExtension
import Observation

#if os(macOS) && canImport(SwiftUI) && canImport(MacrosExtension)

@RouterDestination
enum RouterMacroDestination {
    case detail(id: Int)
    case settings
}

@RouterDestination(generateFlat: false)
enum ExactRouterMacroDestination
{
    case detail(id: Int)
}

@RouterDestination(flatName: "Kind")
enum NamedFlatRouterMacroDestination
{
    case detail(id: Int)
    case settings
}

@Observable
final class RouterMacroDetailModel: RouterDestinationModel {
    typealias Destination = RouterMacroDestination
    
    var id: Int
    
    init(destination: Destination, context: RouterDestinationContext) {
        switch destination {
        case .detail(let id):
            self.id = id
        case .settings:
            self.id = 0
        }
    }
}

@Observable
final class RouterMacroSettingsModel: RouterDestinationModel {
    typealias Destination = RouterMacroDestination
    
    init(destination: Destination, context: RouterDestinationContext) {}
}

struct RouterMacroDetailView: RouterDestinationView {
    typealias Destination = RouterMacroDestination
    typealias Model = RouterMacroDetailModel
    
    static let flats: [Destination.Flat] = [.detail]
    
    @State private var model: Model
    
    init(model: Model) {
        self._model = State(initialValue: model)
    }
    
    var body: some View {
        Text("Detail \(model.id)")
    }
}

struct RouterMacroSettingsView: RouterDestinationView {
    typealias Destination = RouterMacroDestination
    typealias Model = RouterMacroSettingsModel
    
    static let flats: [Destination.Flat] = [.settings]
    
    @State private var model: Model
    
    init(model: Model) {
        self._model = State(initialValue: model)
    }
    
    var body: some View {
        Text("Settings")
    }
}

@MainActor
@Router
final class RouterMacroRouter {
    typealias Destination = RouterMacroDestination
    
    enum PathID: Hashable {
        case root
    }
    
    static let defaultPathID: PathID? = .root
    static let views: [any RouterDestinationView<Destination>.Type] = [
        RouterMacroDetailView.self,
        RouterMacroSettingsView.self,
    ]
    
    var paths: [PathID: [Destination]] = [:]
}

@MainActor
@Router
final class SinglePathRouterMacroRouter
{
    typealias Destination = RouterMacroDestination

    var path: [Destination] = []

    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> some View
    {
        Text(String(describing: destination))
    }
}

@MainActor
@Router
final class CustomStorageRouterMacroRouter
{
    typealias Destination = ExactRouterMacroDestination

    enum PathID: Hashable
    {
        case active
    }

    var storage: [Destination] = []

    static let defaultPathID: PathID? = .active

    func path(for pathID: PathID) -> [Destination]
    {
        storage
    }

    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool
    {
        mutation(&storage)
        return true
    }
}

final class RouterMacroUsageTests: XCTestCase {
    @MainActor
    func testRouterMacroProducesUsablePublicRoutingAPI() {
        let router = RouterMacroRouter()
        router.push(.detail(id: 9))

        XCTAssertEqual(router.path, [.detail(id: 9)])
        XCTAssertNotNil(RouterMacroRouter.viewTypes[.detail])
        XCTAssertNotNil(RouterMacroRouter.viewTypes[.settings])
        _ = router.view(for: .settings)
    }

    @MainActor
    func testRouterMacroInfersSinglePathAndDirectViewProvider()
    {
        let router = SinglePathRouterMacroRouter()

        XCTAssertEqual(router.push(.detail(id: 2)), .main)
        XCTAssertEqual(router.path, [.detail(id: 2)])
        _ = router.view(for: .settings)
    }

    @MainActor
    func testRouterMacroLeavesCustomStorageAvailable()
    {
        let router = CustomStorageRouterMacroRouter()

        XCTAssertEqual(router.push(.detail(id: 5)), .active)
        XCTAssertEqual(router.storage, [.detail(id: 5)])
    }

    func testRouterDestinationMacroSupportsExactAndNamedFlatRepresentations()
    {
        let exact = ExactRouterMacroDestination.detail(id: 4)
        let named = NamedFlatRouterMacroDestination.detail(id: 4)

        XCTAssertEqual(exact.flat, exact)
        XCTAssertEqual(named.flat, .detail)
    }
}

#endif
