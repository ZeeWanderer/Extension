//
//  RouterProtocolTests.swift
//
//
//  Created by zeewanderer on 03.02.2026.
//

import XCTest
import SwiftUI
import Observation
import SwiftUIExtension

#if canImport(SwiftUI) && canImport(MacrosExtension)

enum DemoDestination: RouterDestination {
    case detail(id: Int)
    case settings
    
    enum Flat: Hashable {
        case detail
        case settings
    }
    
    var flat: Flat {
        switch self {
        case .detail:
            return .detail
        case .settings:
            return .settings
        }
    }
}

@Observable
final class DetailModel: RouterDestinationModel {
    typealias Destination = DemoDestination
    
    var id: Int
    var pathID: AnyHashable?
    var requester: AnyHashable?
    
    init(destination: Destination, context: RouterDestinationContext) {
        self.pathID = context.pathID
        self.requester = context.requester
        switch destination {
        case .detail(let id):
            self.id = id
        case .settings:
            self.id = 0
        }
    }
}

@Observable
final class SettingsModel: RouterDestinationModel {
    typealias Destination = DemoDestination
    
    var pathID: AnyHashable?
    var requester: AnyHashable?
    
    init(destination: Destination, context: RouterDestinationContext) {
        self.pathID = context.pathID
        self.requester = context.requester
    }
}

struct DetailView: RouterDestinationView {
    typealias Destination = DemoDestination
    typealias Model = DetailModel
    
    static let flats: [Destination.Flat] = [.detail]
    
    @State private var model: Model
    
    init(model: Model) {
        self._model = State(initialValue: model)
    }
    
    var body: some View {
        Text("Detail \(model.id)")
    }
}

struct SettingsView: RouterDestinationView {
    typealias Destination = DemoDestination
    typealias Model = SettingsModel
    
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
final class DemoRouter: DictionaryRouterProtocol, RouterViewRegistryProtocol {
    typealias Destination = DemoDestination
    
    enum PathID: Hashable {
        case root
        case modal
    }
    
    static let defaultPathID: PathID? = .root
    static let views: [any RouterDestinationView<Destination>.Type] = [
        DetailView.self,
        SettingsView.self,
    ]
    
    static let viewTypes = computeViewTypes()
    
    var paths: [PathID: [Destination]] = [:]
}

final class RouterPublicAPITests: XCTestCase {
    @MainActor
    func testPushAndPopMutateOnlyTheRequestedPath() {
        let router = DemoRouter()

        router.push(.detail(id: 7))
        router.push(.settings, to: .modal)
        router.push(.detail(id: 8), to: .modal)

        XCTAssertEqual(router.path, [.detail(id: 7)])
        XCTAssertEqual(router.path(for: .modal), [.settings, .detail(id: 8)])
        XCTAssertTrue(router.pop(.modal, to: DemoDestination.settings))
        XCTAssertEqual(router.path(for: .modal), [.settings])
        XCTAssertEqual(router.path, [.detail(id: 7)])
    }

    @MainActor
    func testPopToExistingCanCompareExactOrFlatDestinations() {
        var exactPath: [DemoDestination] = [.detail(id: 1), .settings]
        var flatPath: [DemoDestination] = [.detail(id: 1), .settings]

        DemoRouter.push(.detail(id: 2), to: &exactPath, options: [.popToExisting])
        DemoRouter.push(.detail(id: 2), to: &flatPath, options: [.popToExisting, .flatComparison])

        XCTAssertEqual(exactPath, [.detail(id: 1), .settings, .detail(id: 2)])
        XCTAssertEqual(flatPath, [.detail(id: 1)])
    }

    @MainActor
    func testZeroAndOversizedPopCountsDoNotMutateThePath() {
        var path: [DemoDestination] = [.settings, .detail(id: 1)]

        XCTAssertTrue(DemoRouter.pop(&path, amount: 0))
        XCTAssertEqual(path, [.settings, .detail(id: 1)])
        XCTAssertFalse(DemoRouter.pop(&path, amount: 3))
        XCTAssertEqual(path, [.settings, .detail(id: 1)])
        XCTAssertFalse(DemoRouter.pop(&path, amount: -1))
        XCTAssertEqual(path, [.settings, .detail(id: 1)])
    }

    @MainActor
    func testRegisteredViewTypesAndViewFactoriesRemainPublic() {
        let router = DemoRouter()

        XCTAssertNotNil(DemoRouter.viewType(for: .detail))
        XCTAssertNotNil(DemoRouter.viewType(for: .settings))
        _ = router.view(for: .settings, pathID: .modal, requester: "test")
        _ = DemoRouter.view(for: .detail(id: 1), pathID: DemoRouter.PathID.root)
    }
}

#endif
