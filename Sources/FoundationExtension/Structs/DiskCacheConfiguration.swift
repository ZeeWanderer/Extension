//
//  DiskCacheConfiguration.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// Configuration for a file-backed cache store.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct DiskCacheConfiguration: Sendable
{
    /// The cache directory name below `rootDirectory`.
    public var name: String
    /// The parent directory, or the user caches directory when `nil`.
    public var rootDirectory: URL?
    /// Allocated-byte capacity and eviction behavior.
    ///
    /// The default begins maintenance above 400 MiB, trims toward 300 MiB,
    /// protects entries used during the previous ten minutes, and overrides
    /// that protection above a 600 MiB hard ceiling. Use
    /// ``CacheCapacityPolicy/unlimited`` when disk capacity is managed
    /// externally.
    public var capacityPolicy: CacheCapacityPolicy
    /// Optional startup-only sizing derived from available volume capacity.
    ///
    /// When resolution succeeds, it replaces ``capacityPolicy`` for the
    /// lifetime of the resulting ``DiskCacheStorage``. The fixed policy remains
    /// the fallback if the platform cannot provide an available-capacity value.
    public var adaptiveCapacityPolicy: DiskCacheAdaptiveCapacityPolicy?
    /// The minimum interval between automatic full maintenance scans.
    ///
    /// Capacity eviction uses its incremental index and can run before this
    /// interval. This interval controls only reconciliation, invalid-entry,
    /// expiration, and access-age scans.
    public var minimumMaintenanceInterval: TimeInterval
    /// The minimum interval between persisted access-date updates per entry.
    ///
    /// Recent accesses are tracked in memory immediately. Throttling only
    /// reduces metadata writes used to preserve recency across launches.
    public var minimumAccessDateUpdateInterval: TimeInterval
    /// The maximum time since a file was accessed, or `nil` to disable it.
    public var maximumUnusedInterval: TimeInterval?
    /// Whether maintenance proactively removes entries past their expiration.
    public var removesExpiredEntries: Bool
    /// Whether the store requests coalesced maintenance in the background.
    ///
    /// Automatic checks occur when the store is created and after reads and
    /// mutations. Preferred and maximum capacity crossings are edge-triggered,
    /// so remaining above a watermark does not repeatedly schedule eviction.
    /// Set this to `false` when maintenance is driven explicitly through
    /// ``Cache``'s `performMaintenance(storeIDs:mode:failurePolicy:)` methods.
    public var performsAutomaticMaintenance: Bool
    /// The maximum file operations run concurrently by asynchronous maintenance.
    public var maximumConcurrentMaintenanceOperations: Int

    @inlinable
    public init(
        name: String = "disk",
        rootDirectory: URL? = nil,
        capacityPolicy: CacheCapacityPolicy = .soft(
            preferredCapacity: 400 * 1024 * 1024,
            trimToCapacity: 300 * 1024 * 1024,
            maximumCapacity: 600 * 1024 * 1024,
            recentAccessProtectionInterval: 10 * 60
        ),
        adaptiveCapacityPolicy: DiskCacheAdaptiveCapacityPolicy? = nil,
        minimumMaintenanceInterval: TimeInterval = 60 * 60,
        minimumAccessDateUpdateInterval: TimeInterval = 60,
        maximumUnusedInterval: TimeInterval? = 30 * 24 * 60 * 60,
        removesExpiredEntries: Bool = true,
        performsAutomaticMaintenance: Bool = true,
        maximumConcurrentMaintenanceOperations: Int = 8
    )
    {
        self.name = name
        self.rootDirectory = rootDirectory
        self.capacityPolicy = capacityPolicy
        self.adaptiveCapacityPolicy = adaptiveCapacityPolicy
        self.minimumMaintenanceInterval = minimumMaintenanceInterval.isNaN
            ? 0
            : max(0, minimumMaintenanceInterval)
        self.minimumAccessDateUpdateInterval =
            minimumAccessDateUpdateInterval.isNaN
                ? 0
                : max(0, minimumAccessDateUpdateInterval)
        self.maximumUnusedInterval = maximumUnusedInterval.map {
            $0.isNaN ? 0 : max(0, $0)
        }
        self.removesExpiredEntries = removesExpiredEntries
        self.performsAutomaticMaintenance = performsAutomaticMaintenance
        self.maximumConcurrentMaintenanceOperations = max(
            1,
            maximumConcurrentMaintenanceOperations
        )
    }
}
