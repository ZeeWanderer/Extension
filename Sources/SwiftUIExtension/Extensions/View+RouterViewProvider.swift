//
//  View+RouterViewProvider.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import SwiftUI

public extension View
{
    /// Injects destinations rendered by a router instance.
    @MainActor
    func navigationDestinations<R: RouterViewProvider>(
        from router: R,
        pathID: R.PathID? = nil,
        requester: AnyHashable? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) -> some View
    {
        navigationDestination(for: R.Destination.self) { destination in
            router.view(
                for: destination,
                context: router.destinationContext(
                    for: destination,
                    pathID: pathID,
                    requester: requester,
                    userInfo: userInfo
                )
            )
        }
    }

    /// Injects destinations from a static destination view registry.
    @MainActor
    func navigationDestinations<R: RouterViewRegistryProtocol>(
        from routerType: R.Type,
        pathID: AnyHashable? = nil,
        requester: AnyHashable? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) -> some View
    {
        navigationDestination(for: R.Destination.self) { destination in
            routerType.view(
                for: destination,
                context: RouterDestinationContext(
                    pathID: pathID,
                    requester: requester,
                    userInfo: userInfo
                )
            )
        }
    }
}
