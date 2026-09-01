//
//  CacheStoreMaintenanceResult.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

/// Store-agnostic statistics reported after maintenance.
///
/// Capacity values use ``capacityUnit`` rather than assuming bytes. A custom
/// store can report entries, database pages, or another domain-specific unit.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct CacheStoreMaintenanceResult: Hashable, Sendable
{
    /// The work performed by the store.
    public enum Status: Hashable, Sendable
    {
        /// The store does not provide maintenance operations.
        case unsupported
        /// An `ifNeeded` request was throttled because no maintenance was due.
        case skipped
        /// The store completed a maintenance pass.
        case completed
    }

    public let status: Status
    public let scannedEntryCount: Int
    public let removedEntryCount: Int
    /// The unit used by capacity values, or `nil` when none are reported.
    public let capacityUnit: CacheCapacityUnit?
    /// Capacity removed in the store's declared unit.
    public let removedCapacity: UInt64
    public let remainingEntryCount: Int?
    /// Remaining capacity in the store's declared unit.
    public let remainingCapacity: UInt64?
    /// Entries retained because of temporary protection.
    public let protectedEntryCount: Int
    /// Protected capacity in the store's declared unit.
    public let protectedCapacity: UInt64
    /// Whether capacity planning began above the unconditional hard ceiling.
    public let didExceedMaximumCapacity: Bool

    @inlinable
    public init(
        status: Status,
        scannedEntryCount: Int = 0,
        removedEntryCount: Int = 0,
        capacityUnit: CacheCapacityUnit? = nil,
        removedCapacity: UInt64 = 0,
        remainingEntryCount: Int? = nil,
        remainingCapacity: UInt64? = nil,
        protectedEntryCount: Int = 0,
        protectedCapacity: UInt64 = 0,
        didExceedMaximumCapacity: Bool = false
    )
    {
        self.status = status
        self.scannedEntryCount = max(0, scannedEntryCount)
        self.removedEntryCount = max(0, removedEntryCount)
        self.capacityUnit = capacityUnit
        self.removedCapacity = removedCapacity
        self.remainingEntryCount = remainingEntryCount.map { max(0, $0) }
        self.remainingCapacity = remainingCapacity
        self.protectedEntryCount = max(0, protectedEntryCount)
        self.protectedCapacity = protectedCapacity
        self.didExceedMaximumCapacity = didExceedMaximumCapacity
    }

    @inlinable
    public static var unsupported: Self
    {
        Self(status: .unsupported)
    }

    @inlinable
    public static func skipped(
        remainingEntryCount: Int? = nil,
        capacityUnit: CacheCapacityUnit? = nil,
        remainingCapacity: UInt64? = nil
    ) -> Self
    {
        Self(
            status: .skipped,
            capacityUnit: capacityUnit,
            remainingEntryCount: remainingEntryCount,
            remainingCapacity: remainingCapacity
        )
    }
}
