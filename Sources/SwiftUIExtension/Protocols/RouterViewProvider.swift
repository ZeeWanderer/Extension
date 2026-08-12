//
//  RouterViewProvider.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import SwiftUI

/// A router that renders its destinations directly.
///
/// Use this protocol when a destination enum or router-owned `switch` is the
/// clearest place to construct views. Use ``RouterViewRegistryProtocol`` when
/// separate destination view/model registrations are more convenient.
@MainActor
public protocol RouterViewProvider: RouterProtocol
{
    associatedtype DestinationView: View

    @ViewBuilder
    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> DestinationView
}

public extension RouterViewProvider
{
    /// Renders a destination after resolving its construction context.
    func view(
        for destination: Destination,
        pathID: PathID? = nil,
        requester: AnyHashable? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) -> DestinationView
    {
        view(
            for: destination,
            context: destinationContext(
                for: destination,
                pathID: pathID,
                requester: requester,
                userInfo: userInfo
            )
        )
    }
}
