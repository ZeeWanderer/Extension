//
//  CacheRoute.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Selects stores and promotion behavior for one cache key.
///
/// Read stages are searched in order. Async operations query stores in the
/// same stage concurrently and use array order as deterministic hit priority.
/// Synchronous operations query the stage in array order.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheRoute: Sendable
{
    /// Ordered stages of stores to query.
    public var readStages: [[CacheStoreID]]
    /// Stores that receive a write. Other stores have the key invalidated.
    public var writeStores: [CacheStoreID]
    /// Destination stores indexed by the source of a read hit.
    public var promotions: [CacheStoreID: [CacheStoreID]]
    /// The behavior when a read store fails.
    public var readFailurePolicy: CacheFailurePolicy
    /// The behavior when a promotion store fails.
    public var promotionFailurePolicy: CacheFailurePolicy

    @inlinable
    public init(
        readStages: [[CacheStoreID]] = [],
        writeStores: [CacheStoreID] = [],
        promotions: [CacheStoreID: [CacheStoreID]] = [:],
        readFailurePolicy: CacheFailurePolicy = .ignore,
        promotionFailurePolicy: CacheFailurePolicy = .ignore
    )
    {
        self.readStages = readStages
        self.writeStores = writeStores
        self.promotions = promotions
        self.readFailurePolicy = readFailurePolicy
        self.promotionFailurePolicy = promotionFailurePolicy
    }

    /// Builds a conventional fastest-to-slowest hierarchy.
    ///
    /// Reads search one store at a time, writes target every store, and a hit
    /// promotes to every store that precedes its source.
    @inlinable
    public static func hierarchy(_ storeIDs: [CacheStoreID]) -> Self
    {
        var promotions: [CacheStoreID: [CacheStoreID]] = [:]
        for (index, storeID) in storeIDs.enumerated() where index > 0
        {
            promotions[storeID] = Array(storeIDs[..<index])
        }
        return Self(
            readStages: storeIDs.map { [$0] },
            writeStores: storeIDs,
            promotions: promotions
        )
    }
}
