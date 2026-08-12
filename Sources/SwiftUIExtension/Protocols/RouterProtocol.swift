//
//  RouterProtocol.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

/// Storage-independent navigation behavior.
///
/// Adopt ``SinglePathRouterProtocol`` or ``DictionaryRouterProtocol`` for
/// ready-made storage, or implement ``path(for:)`` and ``withPath(_:_:)`` for
/// application-specific storage such as tab roots, nested sheets, or queues.
@MainActor
public protocol RouterProtocol: AnyObject
{
    associatedtype Destination: RouterDestination
    associatedtype PathID: Hashable

    /// A fallback path used when an operation does not explicitly identify one.
    static var defaultPathID: PathID? { get }

    /// Resolves an explicit or implicit path request.
    func resolvePathID(_ pathID: PathID?) -> PathID?

    /// Returns a snapshot of the requested path.
    func path(for pathID: PathID) -> [Destination]

    /// Mutates the requested path when its storage is available.
    /// - Returns: `true` when the path was found and passed to `mutation`.
    @discardableResult
    func withPath(
        _ pathID: PathID,
        _ mutation: (inout [Destination]) -> Void
    ) -> Bool

    /// Returns the root relevant to a proposed destination and path.
    func rootDestination(
        for destination: Destination,
        on pathID: PathID
    ) -> Destination?

    /// Gives a router an opportunity to reject an operation before mutation.
    func shouldPerformNavigation(
        _ operation: RouterNavigationOperation<Destination>,
        on pathID: PathID?
    ) -> Bool

    /// Receives every completed or rejected default navigation operation.
    func routerDidPerform(_ event: RouterNavigationEvent<Destination, PathID>)

    /// Builds the context passed to a destination renderer or model.
    func destinationContext(
        for destination: Destination,
        pathID: PathID?,
        requester: AnyHashable?,
        userInfo: [AnyHashable: Any]
    ) -> RouterDestinationContext

    // Navigation methods are requirements so custom router behavior continues
    // to dispatch when the router is used through a generic protocol constraint.

    @discardableResult
    func push(
        _ destination: Destination,
        to pathID: PathID?,
        options: RouterPushOptions
    ) -> PathID?

    @discardableResult
    func popAll(_ pathID: PathID?) -> Bool

    @discardableResult
    func pop(_ pathID: PathID?, amount: Int) -> Bool

    @discardableResult
    func pop(_ pathID: PathID?, to destination: Destination) -> Bool

    @discardableResult
    func pop(_ pathID: PathID?, toFlat destination: Destination.Flat) -> Bool

    @discardableResult
    func replace(
        _ destination: Destination,
        with replacement: Destination,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Bool

    @discardableResult
    func replace(
        flat: Destination.Flat,
        with replacement: Destination,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Bool

    func contains(_ destination: Destination, on pathID: PathID?) -> Bool
    func contains(flat: Destination.Flat, on pathID: PathID?) -> Bool
    func firstIndex(of destination: Destination, on pathID: PathID?) -> Int?
    func firstIndex(ofFlat flat: Destination.Flat, on pathID: PathID?) -> Int?
    func lastIndex(of destination: Destination, on pathID: PathID?) -> Int?
    func lastIndex(ofFlat flat: Destination.Flat, on pathID: PathID?) -> Int?
    func peek(on pathID: PathID?) -> Destination?
    func peek(
        flat: Destination.Flat,
        on pathID: PathID?,
        search: RouterPathSearchDirection
    ) -> Destination?
}
