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

@Observable
final class RouterMacroDetailModel: RouterDestinationModel {
    typealias Destination = RouterMacroDestination
    
    var id: Int
    
    init(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?) {
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
    
    init(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?) {}
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
    
    static let defaultPathID: PathID = .root
    static let views: [any RouterDestinationView<Destination>.Type] = [
        RouterMacroDetailView.self,
        RouterMacroSettingsView.self,
    ]
    
    var paths: [PathID: [Destination]] = [:]
}

final class RouterMacroUsageTests: XCTestCase {
    @MainActor
    func testRouterMacroUsageCompiles() {
        let router = RouterMacroRouter()
        router.push(.detail(id: 9))
        _ = router.view(for: .settings)
        _ = RouterMacroRouter.viewTypes[.detail]
    }
}

#endif
