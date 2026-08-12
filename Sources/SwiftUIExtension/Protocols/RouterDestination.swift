//
//  RouterDestination.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

/// Base marker for router destinations.
/// A destination can be mapped to a flat (case-only) representation.
public protocol RouterDestination: Hashable
{
    associatedtype Flat: Hashable = Self
    var flat: Flat { get }
}

public extension RouterDestination where Flat == Self
{
    /// Uses the complete destination as its own flat representation.
    var flat: Self { self }
}
