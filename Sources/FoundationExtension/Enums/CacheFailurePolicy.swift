//
//  CacheFailurePolicy.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Selects whether an optional cache operation reports or tolerates a store failure.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public enum CacheFailurePolicy: Hashable, Sendable
{
    /// Report the store failures to the caller.
    case fail
    /// Treat store failures as misses or unsuccessful optional promotions.
    case ignore
}
