//
//  CacheStore.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// An opaque store managed by a ``Cache`` dispatcher.
///
/// Store operations are intentionally not public. Values are read and mutated
/// through `Cache`, preserving its per-key isolation and cross-store rules.
/// Optional maintenance remains dispatcher-controlled while allowing a store
/// to implement its own concurrency-safe eviction policy.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheStore<Key: Hashable & Sendable, Value: Sendable>: Sendable
{
    /// The identifier used by routes and cache hits.
    public let id: CacheStoreID

    @usableFromInline
    internal let p_retrieve: @Sendable (Key) async throws -> CacheEntry<Value>?
    @usableFromInline
    internal let p_store: @Sendable (CacheEntry<Value>, Key) async throws -> Void
    @usableFromInline
    internal let p_remove: @Sendable (Key) async throws -> Void
    @usableFromInline
    internal let p_removeAll: @Sendable () async throws -> Void
    @usableFromInline
    internal let p_maintenance: (@Sendable (CacheMaintenanceMode) async throws -> CacheStoreMaintenanceResult)?
    @usableFromInline
    internal let p_synchronous: CacheStoreSynchronousOperations<Key, Value>?
    @usableFromInline
    internal let p_ownership: P_CacheStoreOwnership

    /// Creates a custom concurrency-safe cache store.
    ///
    /// Async operations must suspend or return rather than block Swift's
    /// cooperative executor. `maintenance` may evict entries while unrelated
    /// cache keys are active, so it must synchronize with this store's other
    /// closures. A store can use ``CacheCapacityPolicy`` with any consistent
    /// capacity unit, or implement an unrelated maintenance strategy. The
    /// dispatcher intentionally does not enumerate an opaque backend. Supply
    /// `synchronous` only for genuine blocking operations on the same backend.
    @inlinable
    public init(
        id: CacheStoreID,
        retrieve: @escaping @Sendable (Key) async throws -> CacheEntry<Value>?,
        store: @escaping @Sendable (CacheEntry<Value>, Key) async throws -> Void,
        remove: @escaping @Sendable (Key) async throws -> Void,
        removeAll: @escaping @Sendable () async throws -> Void,
        maintenance: (@Sendable (CacheMaintenanceMode) async throws -> CacheStoreMaintenanceResult)? = nil,
        synchronous: CacheStoreSynchronousOperations<Key, Value>? = nil
    )
    {
        self.init(
            id: id,
            retrieve: retrieve,
            store: store,
            remove: remove,
            removeAll: removeAll,
            maintenance: maintenance,
            synchronous: synchronous,
            ownership: P_CacheStoreOwnership()
        )
    }

    @inlinable
    internal init(
        id: CacheStoreID,
        retrieve: @escaping @Sendable (Key) async throws -> CacheEntry<Value>?,
        store: @escaping @Sendable (CacheEntry<Value>, Key) async throws -> Void,
        remove: @escaping @Sendable (Key) async throws -> Void,
        removeAll: @escaping @Sendable () async throws -> Void,
        maintenance: (@Sendable (CacheMaintenanceMode) async throws -> CacheStoreMaintenanceResult)?,
        synchronous: CacheStoreSynchronousOperations<Key, Value>?,
        ownership: P_CacheStoreOwnership
    )
    {
        self.id = id
        self.p_retrieve = retrieve
        self.p_store = store
        self.p_remove = remove
        self.p_removeAll = removeAll
        self.p_maintenance = maintenance
        self.p_synchronous = synchronous
        self.p_ownership = ownership
    }
}
