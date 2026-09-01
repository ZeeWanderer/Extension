//
//  RouterDestinationView.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

/// View contract for a router destination.
public protocol RouterDestinationView<Destination>: View
{
    associatedtype Destination: RouterDestination
    associatedtype Model: RouterDestinationModel where Model.Destination == Destination

    /// Flat destinations supported by this view type.
    static var flats: [Destination.Flat] { get }

    /// Builds the view for a destination.
    @MainActor
    static func makeView(
        destination: Destination,
        context: RouterDestinationContext
    ) -> AnyView

    /// Initialize the view with a fully configured model.
    init(model: Model)
}

public extension RouterDestinationView
{
    @MainActor
    static func makeView(
        destination: Destination,
        context: RouterDestinationContext
    ) -> AnyView
    {
        var model = Model(destination: destination, context: context)
        model.configure(destination: destination, context: context)
        return AnyView(Self(model: model))
    }
}
