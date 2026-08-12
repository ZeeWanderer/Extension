//
//  RouterViewRegistryProtocol.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import SwiftUI

/// A view provider backed by separately registered destination view types.
@MainActor
public protocol RouterViewRegistryProtocol: RouterViewProvider
where DestinationView == AnyView
{
    /// Destination view types used by the registry.
    static var views: [any RouterDestinationView<Destination>.Type] { get }

    /// Cached flat destination to view type mapping.
    static var viewTypes: [
        Destination.Flat: any RouterDestinationView<Destination>.Type
    ] { get }

    /// Controls how duplicate flat destination registrations are handled.
    static var viewRegistrationConflictPolicy: RouterViewRegistrationConflictPolicy { get }

    /// Produces a fallback when no view is registered for a destination.
    static func missingDestinationView(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> AnyView
}

public extension RouterViewRegistryProtocol
{
    static var viewRegistrationConflictPolicy: RouterViewRegistrationConflictPolicy
    {
        .precondition
    }

    /// Computes a flat destination to view type mapping from ``views``.
    static func computeViewTypes() -> [
        Destination.Flat: any RouterDestinationView<Destination>.Type
    ]
    {
        var result: [
            Destination.Flat: any RouterDestinationView<Destination>.Type
        ] = [:]

        for viewType in views
        {
            for flat in viewType.flats
            {
                if result[flat] != nil
                {
                    switch viewRegistrationConflictPolicy
                    {
                    case .precondition:
                        preconditionFailure(
                            "Duplicate destination registration for \(flat)"
                        )
                    case .keepFirst:
                        continue
                    case .keepLast:
                        break
                    }
                }

                result[flat] = viewType
            }
        }

        return result
    }

    /// Returns the registered view type for a flat destination.
    static func viewType(
        for flat: Destination.Flat
    ) -> (any RouterDestinationView<Destination>.Type)?
    {
        viewTypes[flat]
    }

    func view(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> AnyView
    {
        Self.view(for: destination, context: context)
    }

    static func view(
        for destination: Destination,
        context: RouterDestinationContext = RouterDestinationContext()
    ) -> AnyView
    {
        guard let viewType = viewType(for: destination.flat) else
        {
            return missingDestinationView(for: destination, context: context)
        }

        return viewType.makeView(destination: destination, context: context)
    }

    /// Renders a registered destination using type-erased path context.
    static func view(
        for destination: Destination,
        pathID: AnyHashable? = nil,
        requester: AnyHashable? = nil,
        userInfo: [AnyHashable: Any] = [:]
    ) -> AnyView
    {
        view(
            for: destination,
            context: RouterDestinationContext(
                pathID: pathID,
                requester: requester,
                userInfo: userInfo
            )
        )
    }

    static func missingDestinationView(
        for destination: Destination,
        context: RouterDestinationContext
    ) -> AnyView
    {
        assertionFailure("Missing destination registration for \(destination.flat)")
        return AnyView(EmptyView())
    }
}
