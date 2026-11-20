//
//  RouterFlexibilityTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import XCTest
import SwiftUI
import SwiftUIExtension

private enum ExactOnlyDestination: RouterDestination
{
    case detail(Int)
}

@MainActor
private final class SinglePathRouter: SinglePathRouterProtocol
{
    typealias Destination = DemoDestination

    var path: [Destination] = []

    func rootDestination(
        for destination: Destination,
        on pathID: PathID
    ) -> Destination?
    {
        switch destination
        {
        case .detail:
            .detail(id: 0)
        case .settings:
            .settings
        }
    }
}

@MainActor
private final class CustomStorageRouter: RouterProtocol
{
    typealias Destination = DemoDestination

    enum PathID: Hashable
    {
        case primary
        case secondary
    }

    var activePathID: PathID = .primary
    static let defaultPathID: PathID? = nil
    var primaryPath: [Destination] = []
    var secondaryPath: [Destination] = []
    var events: [RouterNavigationEvent<Destination, PathID>] = []

    func resolvePathID(_ pathID: PathID?) -> PathID?
    {
        pathID ?? activePathID
    }

    func path(for pathID: PathID) -> [Destination]
    {
        switch pathID
        {
        case .primary:
            primaryPath
        case .secondary:
            secondaryPath
        }
    }

    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool
    {
        switch pathID
        {
        case .primary:
            mutation(&primaryPath)
        case .secondary:
            mutation(&secondaryPath)
        }
        return true
    }

    func shouldPerformNavigation(
        _ operation: RouterNavigationOperation<Destination>,
        on pathID: PathID?
    ) -> Bool
    {
        if case .push(.settings, _) = operation
        {
            return false
        }
        return true
    }

    func routerDidPerform(_ event: RouterNavigationEvent<Destination, PathID>)
    {
        events.append(event)
    }
}

@MainActor
private final class GeneratedPathRouter: RouterProtocol
{
    typealias Destination = DemoDestination

    enum PathID: Hashable
    {
        case sheetRequest
        case sheet(Int)
    }

    var nextSheetID = 0
    static let defaultPathID: PathID? = nil
    var sheetPaths: [Int: [Destination]] = [:]

    func path(for pathID: PathID) -> [Destination]
    {
        guard case let .sheet(id) = pathID else { return [] }
        return sheetPaths[id, default: []]
    }

    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool
    {
        guard case let .sheet(id) = pathID else { return false }
        mutation(&sheetPaths[id, default: []])
        return true
    }

    @discardableResult
    func push(
        _ destination: Destination,
        to requestedPathID: PathID?,
        options: RouterPushOptions
    ) -> PathID?
    {
        guard requestedPathID == .sheetRequest else { return nil }
        nextSheetID += 1
        let resolvedPathID = PathID.sheet(nextSheetID)
        sheetPaths[nextSheetID] = [destination]
        return resolvedPathID
    }
}

@MainActor
private final class DirectViewRouter: SinglePathRouterProtocol, RouterViewProvider
{
    typealias Destination = DemoDestination

    var path: [Destination] = []
    var lastContext: RouterDestinationContext?

    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> some View
    {
        lastContext = context
        return Text(String(describing: destination))
    }
}

@MainActor
private final class CustomReplacementRouter: SinglePathRouterProtocol
{
    typealias Destination = DemoDestination

    var path: [Destination] = []
    var replacementCallCount = 0

    @discardableResult
    func replace(
        _ destination: Destination,
        with replacement: Destination,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Bool
    {
        replacementCallCount += 1
        path = path.map { value in
            value == destination ? replacement : value
        }
        return true
    }
}

@MainActor
private final class MutationReadTrackingRouter: SinglePathRouterProtocol
{
    typealias Destination = DemoDestination

    var path: [Destination] = []
    var pathReadCount = 0
    var events: [RouterNavigationEvent<Destination, PathID>] = []

    func path(for pathID: PathID) -> [Destination]
    {
        pathReadCount += 1
        return path
    }

    func routerDidPerform(_ event: RouterNavigationEvent<Destination, PathID>)
    {
        events.append(event)
    }
}

private struct AlternateDetailView: RouterDestinationView
{
    typealias Destination = DemoDestination
    typealias Model = DetailModel

    static let flats: [Destination.Flat] = [.detail]

    @State private var model: Model

    init(model: Model)
    {
        self._model = State(initialValue: model)
    }

    var body: some View
    {
        Text("Alternate \(model.id)")
    }
}

@MainActor
private final class FirstRegistrationRouter:
    SinglePathRouterProtocol,
    RouterViewRegistryProtocol
{
    typealias Destination = DemoDestination

    static let views: [any RouterDestinationView<Destination>.Type] = [
        DetailView.self,
        AlternateDetailView.self,
    ]
    static let viewRegistrationConflictPolicy: RouterViewRegistrationConflictPolicy = .keepFirst
    static let viewTypes = computeViewTypes()

    var path: [Destination] = []
}

@MainActor
private final class LastRegistrationRouter:
    SinglePathRouterProtocol,
    RouterViewRegistryProtocol
{
    typealias Destination = DemoDestination

    static let views: [any RouterDestinationView<Destination>.Type] = [
        DetailView.self,
        AlternateDetailView.self,
    ]
    static let viewRegistrationConflictPolicy: RouterViewRegistrationConflictPolicy = .keepLast
    static let viewTypes = computeViewTypes()

    var path: [Destination] = []
}

private extension GeneratedPathRouter
{
    static func pushThroughProtocol<R: RouterProtocol>(
        _ destination: R.Destination,
        using router: R,
        to pathID: R.PathID
    ) -> R.PathID?
    {
        router.push(destination, to: pathID)
    }
}

@MainActor
private func replaceThroughProtocol<R: RouterProtocol>(
    using router: R,
    destination: R.Destination,
    replacement: R.Destination
) -> Bool
{
    router.replace(destination, with: replacement)
}

final class RouterFlexibilityTests: XCTestCase
{
    func testDestinationCanUseItselfWhenCaseOnlyComparisonIsNotNeeded()
    {
        let destination = ExactOnlyDestination.detail(4)

        XCTAssertEqual(destination.flat, destination)
    }

    @MainActor
    func testSinglePathStorageAndRootDestinationNeedNoDictionary()
    {
        let router = SinglePathRouter()

        XCTAssertEqual(router.push(.detail(id: 1)), .main)
        XCTAssertEqual(router.push(.detail(id: 2)), .main)
        XCTAssertEqual(router.push(.settings, options: [.popToExisting]), .main)

        XCTAssertEqual(router.path, [])
        XCTAssertEqual(router.path(for: .main), [])

        router.path = [.settings]
        XCTAssertEqual(
            router.push(
                .detail(id: 99),
                options: [.popToExisting, .flatComparison]
            ),
            .main
        )
        XCTAssertEqual(router.path, [])
    }

    @MainActor
    func testCustomStorageCanResolveAnActivePathAndObserveRejectedOperations()
    {
        let router = CustomStorageRouter()
        router.activePathID = .secondary

        XCTAssertEqual(router.push(.detail(id: 7)), .secondary)
        XCTAssertNil(router.push(.settings))

        XCTAssertEqual(router.primaryPath, [])
        XCTAssertEqual(router.secondaryPath, [.detail(id: 7)])
        XCTAssertEqual(router.events.count, 2)
        XCTAssertTrue(router.events[0].succeeded)
        XCTAssertFalse(router.events[1].succeeded)
        XCTAssertFalse(router.events[1].didChangePathDepth)
    }

    @MainActor
    func testCustomNavigationRequirementDispatchesThroughGenericCode()
    {
        let router = GeneratedPathRouter()

        let resolvedPathID = GeneratedPathRouter.pushThroughProtocol(
            .detail(id: 3),
            using: router,
            to: .sheetRequest
        )

        XCTAssertEqual(resolvedPathID, .sheet(1))
        XCTAssertEqual(router.path(for: .sheet(1)), [.detail(id: 3)])
    }

    @MainActor
    func testPathQueriesAndReplacementSupportExactAndFlatDestinations()
    {
        let router = SinglePathRouter()
        router.path = [.detail(id: 1), .settings, .detail(id: 2)]

        XCTAssertTrue(router.contains(.detail(id: 1)))
        XCTAssertTrue(router.contains(flat: .detail))
        XCTAssertEqual(router.firstIndex(ofFlat: .detail), 0)
        XCTAssertEqual(router.lastIndex(ofFlat: .detail), 2)
        XCTAssertEqual(router.peek(flat: .detail, search: .first), .detail(id: 1))
        XCTAssertEqual(router.peek(), .detail(id: 2))

        XCTAssertTrue(router.replace(flat: .detail, with: .detail(id: 8), search: .first))
        XCTAssertTrue(router.replace(.detail(id: 2), with: .settings))
        XCTAssertEqual(router.path, [.detail(id: 8), .settings, .settings])
    }

    @MainActor
    func testDirectViewProviderReceivesResolvedContextWithoutARegistry()
    {
        let router = DirectViewRouter()

        _ = router.view(
            for: .settings,
            requester: "test",
            userInfo: ["source": "unit-test"]
        )

        XCTAssertEqual(router.lastContext?.pathID, AnyHashable(RouterSinglePathID.main))
        XCTAssertEqual(router.lastContext?.requester, AnyHashable("test"))
        XCTAssertEqual(
            router.lastContext?.pathID(as: RouterSinglePathID.self),
            .main
        )
        XCTAssertEqual(router.lastContext?.requester(as: String.self), "test")
        XCTAssertEqual(router.lastContext?.value(for: "source", as: String.self), "unit-test")
    }

    @MainActor
    func testReplacementOverrideDispatchesThroughConvenienceAPI()
    {
        let router = CustomReplacementRouter()
        router.path = [.detail(id: 1), .settings, .detail(id: 1)]

        XCTAssertTrue(replaceThroughProtocol(
            using: router,
            destination: .detail(id: 1),
            replacement: .detail(id: 2)
        ))

        XCTAssertEqual(router.replacementCallCount, 1)
        XCTAssertEqual(
            router.path,
            [.detail(id: 2), .settings, .detail(id: 2)]
        )
    }

    @MainActor
    func testRegistryConflictPolicyCanSelectFirstOrLastRegistration()
    {
        let first = FirstRegistrationRouter.viewType(for: .detail)
        let last = LastRegistrationRouter.viewType(for: .detail)

        XCTAssertEqual(
            first.map { ObjectIdentifier($0) },
            ObjectIdentifier(DetailView.self)
        )
        XCTAssertEqual(
            last.map { ObjectIdentifier($0) },
            ObjectIdentifier(AlternateDetailView.self)
        )
    }

    @MainActor
    func testDefaultMutationDoesNotSnapshotPathStorage()
    {
        let router = MutationReadTrackingRouter()

        XCTAssertEqual(router.push(.detail(id: 1)), .main)

        XCTAssertEqual(router.pathReadCount, 0)
        XCTAssertEqual(router.events.first?.pathCountBefore, 0)
        XCTAssertEqual(router.events.first?.pathCountAfter, 1)
    }
}
