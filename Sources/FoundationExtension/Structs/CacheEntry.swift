//
//  CacheEntry.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// A value and the metadata preserved while it moves between cache stores.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheEntry<Value: Sendable>: Sendable
{
    /// The cached value.
    public var value: Value
    /// The time at which the value entered the cache hierarchy.
    public var storedAt: Date
    /// The first date at which the value should be treated as a miss.
    public var expirationDate: Date?
    /// An optional in-memory eviction cost. Zero asks the store to calculate it.
    public var cost: Int

    @inlinable
    public init(
        _ value: Value,
        storedAt: Date = .now,
        expirationDate: Date? = nil,
        cost: Int = 0
    )
    {
        self.value = value
        self.storedAt = storedAt
        self.expirationDate = expirationDate
        self.cost = max(0, cost)
    }

    /// Returns whether the entry has reached its expiration date.
    @inlinable
    public func isExpired(at date: Date = .now) -> Bool
    {
        expirationDate.map { date >= $0 } ?? false
    }
}

/// A cache entry together with the store that supplied it.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheHit<Value: Sendable>: Sendable
{
    /// The value and metadata returned by the source store.
    public let entry: CacheEntry<Value>
    /// The store that supplied the entry before any promotion.
    public let storeID: CacheStoreID

    @inlinable
    public init(entry: CacheEntry<Value>, storeID: CacheStoreID)
    {
        self.entry = entry
        self.storeID = storeID
    }

    /// The cached value.
    @inlinable
    public var value: Value { entry.value }
}
