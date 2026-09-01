//
//  P_MemoryCacheStore.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_MemoryCacheStore<
    Key: Hashable & Sendable,
    Value: Sendable
>: @unchecked Sendable
{
    @usableFromInline
    internal final class WrappedKey: NSObject
    {
        @usableFromInline internal let key: Key

        @inlinable
        internal init(_ key: Key)
        {
            self.key = key
        }

        @inlinable
        override internal var hash: Int { key.hashValue }

        @inlinable
        override internal func isEqual(_ object: Any?) -> Bool
        {
            guard let object = object as? WrappedKey else { return false }
            return object.key == key
        }
    }

    @usableFromInline
    internal final class EntryBox
    {
        @usableFromInline internal let entry: CacheEntry<Value>

        @inlinable
        internal init(_ entry: CacheEntry<Value>)
        {
            self.entry = entry
        }
    }

    @usableFromInline internal let cache = NSCache<WrappedKey, EntryBox>()
    @usableFromInline internal let cost: @Sendable (Value) -> Int

    @inlinable
    internal init(
        configuration: MemoryCacheConfiguration,
        cost: @escaping @Sendable (Value) -> Int
    )
    {
        self.cost = cost
        cache.name = configuration.name
        cache.countLimit = configuration.countLimit
        cache.totalCostLimit = configuration.totalCostLimit
        cache.evictsObjectsWithDiscardedContent =
            configuration.evictsObjectsWithDiscardedContent
    }

    @inlinable
    internal func retrieve(for key: Key) -> CacheEntry<Value>?
    {
        let wrappedKey = WrappedKey(key)
        guard let entry = cache.object(forKey: wrappedKey)?.entry else
        {
            return nil
        }
        guard !entry.isExpired() else
        {
            cache.removeObject(forKey: wrappedKey)
            return nil
        }
        return entry
    }

    @inlinable
    internal func store(_ entry: CacheEntry<Value>, for key: Key)
    {
        let configuredCost = max(0, cost(entry.value))
        cache.setObject(
            EntryBox(entry),
            forKey: WrappedKey(key),
            cost: entry.cost > 0 ? entry.cost : configuredCost
        )
    }

    @inlinable
    internal func remove(for key: Key)
    {
        cache.removeObject(forKey: WrappedKey(key))
    }

    @inlinable
    internal func removeAll()
    {
        cache.removeAllObjects()
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheStore
{
    /// Creates an `NSCache`-backed store.
    @inlinable
    static func memory(
        id: CacheStoreID = .memory,
        configuration: MemoryCacheConfiguration = .init(),
        cost: @escaping @Sendable (Value) -> Int = { _ in 0 }
    ) -> Self
    {
        let store = P_MemoryCacheStore<Key, Value>(
            configuration: configuration,
            cost: cost
        )
        let synchronous = CacheStoreSynchronousOperations<Key, Value>(
            retrieve: { key in
                store.retrieve(for: key)
            },
            store: { entry, key in
                store.store(entry, for: key)
            },
            remove: { key in
                store.remove(for: key)
            },
            removeAll: {
                store.removeAll()
            }
        )
        return Self(
            id: id,
            retrieve: { key in
                store.retrieve(for: key)
            },
            store: { entry, key in
                store.store(entry, for: key)
            },
            remove: { key in
                store.remove(for: key)
            },
            removeAll: {
                store.removeAll()
            },
            maintenance: nil,
            synchronous: synchronous
        )
    }
}
