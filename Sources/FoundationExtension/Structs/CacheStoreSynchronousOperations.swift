//
//  CacheStoreSynchronousOperations.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Blocking operations for a custom ``CacheStore``.
///
/// Supplying these operations makes the store available to the synchronous
/// cache API. Async-only stores remain usable through the async API.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheStoreSynchronousOperations<
    Key: Hashable & Sendable,
    Value: Sendable
>: Sendable
{
    @usableFromInline
    internal let p_retrieve: @Sendable (Key) throws -> CacheEntry<Value>?
    @usableFromInline
    internal let p_store: @Sendable (CacheEntry<Value>, Key) throws -> Void
    @usableFromInline
    internal let p_remove: @Sendable (Key) throws -> Void
    @usableFromInline
    internal let p_removeAll: @Sendable () throws -> Void
    @usableFromInline
    internal let p_maintenance: (@Sendable (CacheMaintenanceMode) throws -> CacheStoreMaintenanceResult)?

    @inlinable
    public init(
        retrieve: @escaping @Sendable (Key) throws -> CacheEntry<Value>?,
        store: @escaping @Sendable (CacheEntry<Value>, Key) throws -> Void,
        remove: @escaping @Sendable (Key) throws -> Void,
        removeAll: @escaping @Sendable () throws -> Void,
        maintenance: (@Sendable (CacheMaintenanceMode) throws -> CacheStoreMaintenanceResult)? = nil
    )
    {
        self.p_retrieve = retrieve
        self.p_store = store
        self.p_remove = remove
        self.p_removeAll = removeAll
        self.p_maintenance = maintenance
    }
}
