//
//  RouterDestinationModel.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

/// Model contract for a router destination.
public protocol RouterDestinationModel {
    associatedtype Destination: RouterDestination
    
    /// Initialize model from destination and context.
    /// - Parameters:
    ///   - destination: Destination passed by the router.
    ///   - pathID: Optional path identifier (tab, sheet, overlay, etc).
    ///   - requester: Optional requester identifier for context-aware configuration.
    init(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?)
    
    /// Additional configuration hook. Default implementation does nothing.
    mutating func configure(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?)
}

public extension RouterDestinationModel {
    mutating func configure(destination: Destination, pathID: AnyHashable?, requester: AnyHashable?) {}
}
