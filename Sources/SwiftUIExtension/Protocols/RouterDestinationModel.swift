//
//  RouterDestinationModel.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

/// Model contract for a router destination.
public protocol RouterDestinationModel
{
    associatedtype Destination: RouterDestination

    /// Initialize model from destination and context.
    /// - Parameters:
    ///   - destination: Destination passed by the router.
    ///   - context: Path, requester, and application-defined construction data.
    init(destination: Destination, context: RouterDestinationContext)

    /// Additional configuration hook. Default implementation does nothing.
    mutating func configure(
        destination: Destination,
        context: RouterDestinationContext
    )
}

public extension RouterDestinationModel
{
    mutating func configure(
        destination: Destination,
        context: RouterDestinationContext
    ) {}
}
