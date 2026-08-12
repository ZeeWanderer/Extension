//
//  RouterNavigationEvent.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Describes a completed or rejected navigation request.
public struct RouterNavigationEvent<Destination, PathID>
where Destination: RouterDestination, PathID: Hashable
{
    public let operation: RouterNavigationOperation<Destination>
    public let requestedPathID: PathID?
    public let resolvedPathID: PathID?
    /// Path depth immediately before an attempted in-place mutation.
    public let pathCountBefore: Int?
    /// Path depth immediately after an attempted in-place mutation.
    public let pathCountAfter: Int?
    public let succeeded: Bool

    public init(
        operation: RouterNavigationOperation<Destination>,
        requestedPathID: PathID?,
        resolvedPathID: PathID?,
        pathCountBefore: Int?,
        pathCountAfter: Int?,
        succeeded: Bool
    )
    {
        self.operation = operation
        self.requestedPathID = requestedPathID
        self.resolvedPathID = resolvedPathID
        self.pathCountBefore = pathCountBefore
        self.pathCountAfter = pathCountAfter
        self.succeeded = succeeded
    }

    /// Whether the operation changed the path depth.
    ///
    /// A successful replacement can mutate a path without changing its depth.
    public var didChangePathDepth: Bool
    {
        pathCountBefore != pathCountAfter
    }
}
