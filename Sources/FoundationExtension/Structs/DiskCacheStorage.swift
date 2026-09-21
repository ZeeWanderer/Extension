//
//  DiskCacheStorage.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// Owns one physical cache directory shared by object and specialized caches.
///
/// Capacity, recency, maintenance, and cache-wide barriers are coordinated at
/// this boundary. A regular ``CacheStore`` and any number of ``SparseCache``
/// namespaces can therefore share one disk budget without exposing their files.
/// The directory is exclusively owned by this type; callers must not add or
/// mutate files through ``directoryURL``.
///
/// Coordination is process-local. An App Group location may be used to retain
/// data across an app and its extensions, but simultaneous access from multiple
/// processes requires an external process-level exclusion boundary.
///
/// Async maintenance and removal leave the caller's actor in the same task;
/// blocking file I/O runs on a dedicated task executor.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public final class DiskCacheStorage: @unchecked Sendable
{
    public let name: String
    public let location: DiskCacheLocation
    public let directoryURL: URL
    /// The fixed capacity policy resolved for this storage lifetime.
    public let capacityPolicy: CacheCapacityPolicy
    /// The startup sizing rule used to resolve ``capacityPolicy``, if any.
    public let adaptiveCapacityPolicy: DiskCacheAdaptiveCapacityPolicy?
    public let minimumMaintenanceInterval: TimeInterval
    public let minimumAccessDateUpdateInterval: TimeInterval
    public let maximumUnusedInterval: TimeInterval?
    public let removesExpiredEntries: Bool
    public let performsAutomaticMaintenance: Bool
    public let maximumConcurrentMaintenanceOperations: Int

    @usableFromInline internal let p_fileManager: FileManager
    @usableFromInline
    internal let p_coordinator: P_CacheDiskDirectoryCoordinator
    @usableFromInline internal let p_ioExecutor: P_CacheIOExecutor
    @usableFromInline
    internal let p_maintenance: P_DiskCacheStorageMaintenance

    public init(
        name: String = "disk",
        location: DiskCacheLocation = .cachesDirectory,
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
    ) throws
    {
        guard Self.p_isValidDirectoryName(name) else
        {
            throw CacheError.invalidDiskConfiguration(
                "The disk cache name must be a nonempty path component"
            )
        }

        let fileManager = FileManager.default
        let parent = try location.p_resolvedDirectory(fileManager: fileManager)
        let directory = parent.appending(
            component: name,
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        if let excludesFromBackup = location.p_excludesFromBackup
        {
            var values = URLResourceValues()
            values.isExcludedFromBackup = excludesFromBackup
            var mutableDirectory = directory
            try mutableDirectory.setResourceValues(values)
        }

        let normalizedMinimumMaintenanceInterval =
            minimumMaintenanceInterval.isNaN
                ? 0
                : max(0, minimumMaintenanceInterval)
        let normalizedMinimumAccessDateUpdateInterval =
            minimumAccessDateUpdateInterval.isNaN
                ? 0
                : max(0, minimumAccessDateUpdateInterval)
        let normalizedMaximumUnusedInterval = maximumUnusedInterval.map {
            $0.isNaN ? 0 : max(0, $0)
        }
        let initialCapacity = try Self.p_indexedCapacity(
            in: directory,
            fileManager: fileManager
        )
        let resolvedCapacityPolicy = adaptiveCapacityPolicy.flatMap {
            Self.p_resolvedCapacityPolicy(
                $0,
                for: directory,
                existingCacheCapacity: initialCapacity
            )
        } ?? capacityPolicy
        let coordinator = P_CacheDiskDirectoryRegistry.coordinator(
            for: directory,
            initialCapacity: initialCapacity
        )
        let ioExecutor = P_CacheIOExecutor(
            label: "Extension.DiskCache.\(name)"
        )

        self.name = name
        self.location = location
        self.directoryURL = directory
        self.capacityPolicy = resolvedCapacityPolicy
        self.adaptiveCapacityPolicy = adaptiveCapacityPolicy
        self.minimumMaintenanceInterval =
            normalizedMinimumMaintenanceInterval
        self.minimumAccessDateUpdateInterval =
            normalizedMinimumAccessDateUpdateInterval
        self.maximumUnusedInterval = normalizedMaximumUnusedInterval
        self.removesExpiredEntries = removesExpiredEntries
        self.performsAutomaticMaintenance = performsAutomaticMaintenance
        self.maximumConcurrentMaintenanceOperations = max(
            1,
            maximumConcurrentMaintenanceOperations
        )
        self.p_fileManager = fileManager
        self.p_coordinator = coordinator
        self.p_ioExecutor = ioExecutor
        self.p_maintenance = P_DiskCacheStorageMaintenance(
            directory: directory,
            capacityPolicy: resolvedCapacityPolicy,
            minimumMaintenanceInterval:
                normalizedMinimumMaintenanceInterval,
            maximumUnusedInterval: normalizedMaximumUnusedInterval,
            removesExpiredEntries: removesExpiredEntries,
            performsAutomaticMaintenance: performsAutomaticMaintenance,
            maximumConcurrentOperations: max(
                1,
                maximumConcurrentMaintenanceOperations
            ),
            fileManager: fileManager,
            coordinator: coordinator,
            ioExecutor: ioExecutor
        )
        p_requestAutomaticMaintenance()
    }

    @inlinable
    internal convenience init(configuration: DiskCacheConfiguration) throws
    {
        try self.init(
            name: configuration.name,
            location: configuration.rootDirectory.map {
                .custom($0)
            } ?? .cachesDirectory,
            capacityPolicy: configuration.capacityPolicy,
            adaptiveCapacityPolicy: configuration.adaptiveCapacityPolicy,
            minimumMaintenanceInterval:
                configuration.minimumMaintenanceInterval,
            minimumAccessDateUpdateInterval:
                configuration.minimumAccessDateUpdateInterval,
            maximumUnusedInterval: configuration.maximumUnusedInterval,
            removesExpiredEntries: configuration.removesExpiredEntries,
            performsAutomaticMaintenance:
                configuration.performsAutomaticMaintenance,
            maximumConcurrentMaintenanceOperations:
                configuration.maximumConcurrentMaintenanceOperations
        )
    }

    /// Performs aggregate maintenance across every cache namespace in storage.
    @available(*, noasync, message: "Use the async storage API from an async context")
    public func performMaintenance(
        _ mode: CacheMaintenanceMode = .forced
    ) throws -> CacheStoreMaintenanceResult
    {
        try p_maintenance.performSynchronously(mode)
    }

    /// Performs aggregate maintenance without blocking the caller.
    @concurrent
    public func performMaintenance(
        _ mode: CacheMaintenanceMode = .forced
    ) async throws -> CacheStoreMaintenanceResult
    {
        try await p_maintenance.perform(mode)
    }

    /// Removes all object and specialized cache namespaces in this storage.
    @available(*, noasync, message: "Use the async storage API from an async context")
    public func removeAll() throws
    {
        try p_maintenance.removeAllSynchronously()
    }

    /// Removes all object and specialized cache namespaces without blocking.
    @concurrent
    public func removeAll() async throws
    {
        try await p_maintenance.removeAll()
    }

    @inlinable
    internal func p_requestAutomaticMaintenance()
    {
        p_maintenance.requestAutomaticMaintenance()
    }

    @inlinable
    internal static func p_isValidDirectoryName(_ name: String) -> Bool
    {
        !name.isEmpty
            && name != "."
            && name != ".."
            && !name.contains("/")
    }

    @usableFromInline
    internal static func p_indexedCapacity(
        in directory: URL,
        fileManager: FileManager
    ) throws -> UInt64
    {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
            ],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var result: UInt64 = 0
        for case let url as URL in enumerator
        {
            let values = try? url.resourceValues(forKeys: [
                .isRegularFileKey,
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
            ])
            guard values?.isRegularFile == true else { continue }
            let capacity = P_DiskCacheStorageMaintenance.fileCapacity(
                from: values ?? URLResourceValues()
            )
            let (sum, overflow) = result.addingReportingOverflow(capacity)
            result = overflow ? .max : sum
        }
        return result
    }

    @usableFromInline
    internal static func p_resolvedCapacityPolicy(
        _ adaptivePolicy: DiskCacheAdaptiveCapacityPolicy,
        for directory: URL,
        existingCacheCapacity: UInt64
    ) -> CacheCapacityPolicy?
    {
        let values: URLResourceValues
        do
        {
            switch adaptivePolicy.usage
            {
            case .opportunistic:
                values = try directory.resourceValues(forKeys: [
                    .volumeAvailableCapacityForOpportunisticUsageKey,
                ])
            case .important:
                values = try directory.resourceValues(forKeys: [
                    .volumeAvailableCapacityForImportantUsageKey,
                ])
            }
        }
        catch { return nil }

        let availableCapacity: Int64?
        switch adaptivePolicy.usage
        {
        case .opportunistic:
            availableCapacity =
                values.volumeAvailableCapacityForOpportunisticUsage
        case .important:
            availableCapacity = values.volumeAvailableCapacityForImportantUsage
        }
        guard let availableCapacity, availableCapacity >= 0 else { return nil }
        return adaptivePolicy.capacityPolicy(
            availableCapacity: UInt64(availableCapacity),
            existingCacheCapacity: existingCacheCapacity
        )
    }
}
