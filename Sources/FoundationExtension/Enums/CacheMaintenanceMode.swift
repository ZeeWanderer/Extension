//
//  CacheMaintenanceMode.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

/// Selects whether cache maintenance observes its configured throttle.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public enum CacheMaintenanceMode: Hashable, Sendable
{
    /// Performs maintenance only when the store reports that it is due.
    case ifNeeded
    /// Performs a complete maintenance pass now.
    ///
    /// This still applies the store's configured expiration, age, and size
    /// policies. It does not remove otherwise valid entries merely because the
    /// pass was forced.
    case forced
    /// Performs a complete maintenance pass and permits stores to ignore
    /// temporary eviction protections.
    ///
    /// The built-in disk store can evict recently used entries toward its trim
    /// target in this mode. Expiration, capacity, and backend invariants still
    /// apply; custom stores decide which protections are safe to override.
    case aggressive
}
