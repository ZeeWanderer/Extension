//
//  RouterProtocolTests.swift
//
//
//  Created by zeewanderer on 03.02.2026.
//

import XCTest
import SwiftUI
import Observation
@testable import SwiftUIExtension

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
    
    init(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?) {
        self.pathID = pathID
        self.requester = requester
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
    
    init(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?) {
        self.pathID = pathID
        self.requester = requester
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
final class DemoRouter: RouterProtocol {
    typealias Destination = DemoDestination
    
    enum PathID: Hashable {
        case root
        case modal
    }
    
    static let defaultPathID: PathID = .root
    static let views: [any RouterDestinationView<Destination>.Type] = [
        DetailView.self,
        SettingsView.self,
    ]
    
    static let viewTypes = computeViewTypes()
    
    var paths: [PathID: [Destination]] = [:]
}

final class RouterProtocolTests: XCTestCase {
    @MainActor
    func testRouterBuildsViews() {
        let router = DemoRouter()
        
        router.push(.detail(id: 7))
        XCTAssertEqual(router.path.count, 1)
        
        _ = router.view(for: .settings, pathID: .modal)
        _ = DemoRouter.view(for: .detail(id: 1))
    }
}

#endif
