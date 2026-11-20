//
//  RouterProtocol+Customization.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

public extension RouterProtocol
{
    func resolvePathID(_ pathID: PathID?) -> PathID?
    {
        pathID ?? Self.defaultPathID
    }

    func rootDestination(
        for destination: Destination,
        on pathID: PathID
    ) -> Destination?
    {
        nil
    }

    func shouldPerformNavigation(
        _ operation: RouterNavigationOperation<Destination>,
        on pathID: PathID?
    ) -> Bool
    {
        true
    }

    func routerDidPerform(_ event: RouterNavigationEvent<Destination, PathID>) {}

    func destinationContext(
        for destination: Destination,
        pathID: PathID?,
        requester: AnyHashable?,
        userInfo: [AnyHashable: Any]
    ) -> RouterDestinationContext
    {
        let resolvedPathID: AnyHashable?
        if let pathID = resolvePathID(pathID)
        {
            resolvedPathID = AnyHashable(pathID)
        }
        else
        {
            resolvedPathID = nil
        }
        return RouterDestinationContext(
            pathID: resolvedPathID,
            requester: requester,
            userInfo: userInfo
        )
    }

    func destinationContext(
        for destination: Destination
    ) -> RouterDestinationContext
    {
        destinationContext(
            for: destination,
            pathID: Optional<PathID>.none,
            requester: nil,
            userInfo: [:]
        )
    }
}
