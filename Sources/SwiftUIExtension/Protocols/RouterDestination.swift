//
//  RouterDestination.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

import SwiftUI

/// Base marker for router destinations.
/// A destination can be mapped to a flat (case-only) representation.
public protocol RouterDestination: Hashable {
    associatedtype Flat: Hashable
    var flat: Flat { get }
}
