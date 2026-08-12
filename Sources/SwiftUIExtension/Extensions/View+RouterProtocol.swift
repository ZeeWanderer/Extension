//
//  View+RouterProtocol.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

public extension View {
    /// Injects router destinations into the navigation stack.
    @MainActor
    func navigationDestinations<R: RouterProtocol>(
        from router: R,
        pathID: R.PathID? = nil,
        requester: AnyHashable? = nil
    ) -> some View {
        navigationDestination(for: R.Destination.self) { destination in
            router.view(for: destination, pathID: pathID, requester: requester)
        }
    }

    /// Injects router destinations into the navigation stack using the router type.
    @MainActor
    func navigationDestinations<R: RouterProtocol>(
        from routerType: R.Type,
        pathID: AnyHashable? = nil,
        requester: AnyHashable? = nil
    ) -> some View {
        navigationDestination(for: R.Destination.self) { destination in
            routerType.view(for: destination, pathID: pathID, requester: requester)
        }
    }
}
