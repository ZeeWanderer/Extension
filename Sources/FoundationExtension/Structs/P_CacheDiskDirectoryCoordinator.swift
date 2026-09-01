//
//  P_CacheDiskDirectoryCoordinator.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal enum P_CacheAutomaticMaintenanceReason: Hashable, Sendable
{
    case capacity
    case reconciliation
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheDiskDirectoryCoordinator: @unchecked Sendable
{
    @usableFromInline internal let accessGate = P_CacheReadWriteGate()
    @usableFromInline internal let maintenanceGate = P_CacheReadWriteGate()
    @usableFromInline
    internal let fileGates = P_CacheKeyGateRegistry<URL>(
        maximumRetainedGateCount: 1024
    )
    @usableFromInline
    internal let sparseResources = P_SparseCacheResourceRegistry(
        maximumRetainedResourceCount: 256
    )
    @usableFromInline internal let ownership = P_CacheStoreOwnership()

    @usableFromInline internal let stateLock = NSLock()
    @usableFromInline internal var totalCapacity: UInt64
    @usableFromInline internal var lastMaintenanceDate = Date.distantPast
    @usableFromInline internal var automaticMaintenanceIsScheduled = false
    @usableFromInline internal var automaticMaintenanceNeedsRecheck = false
    @usableFromInline internal var preferredCapacityTriggerIsArmed = true
    @usableFromInline internal var maximumCapacityTriggerIsArmed = true
    @usableFromInline internal var automaticPreferredCapacity: UInt64?
    @usableFromInline internal var automaticMaximumCapacity: UInt64?
    @usableFromInline internal var recentAccessDates: [URL: Date] = [:]
    @usableFromInline internal var persistedAccessDates: [URL: Date] = [:]
    @usableFromInline
    internal var diskEntryRecords: [URL: P_CacheDiskEntryRecord] = [:]
    @usableFromInline internal var diskEntryIndexIsComplete = false
    @usableFromInline internal var diskEntryIndexGeneration: UInt64 = 0

    @inlinable
    internal init(totalCapacity: UInt64)
    {
        self.totalCapacity = totalCapacity
    }

    @inlinable
    internal func state() -> (
        totalCapacity: UInt64,
        lastMaintenanceDate: Date
    )
    {
        stateLock.lock()
        defer { stateLock.unlock() }
        return (totalCapacity, lastMaintenanceDate)
    }

    @inlinable
    internal func updateTotalCapacity(
        from oldCapacity: UInt64,
        to newCapacity: UInt64
    )
    {
        stateLock.lock()
        if newCapacity >= oldCapacity
        {
            let (updatedCapacity, overflow) = totalCapacity
                .addingReportingOverflow(
                    newCapacity - oldCapacity
                )
            totalCapacity = overflow ? .max : updatedCapacity
        }
        else
        {
            totalCapacity = totalCapacity >= oldCapacity - newCapacity
                ? totalCapacity - (oldCapacity - newCapacity)
                : 0
        }
        p_rearmAutomaticCapacityTriggers()
        stateLock.unlock()
    }

    @inlinable
    internal func recordStoredEntry(_ record: P_CacheDiskEntryRecord)
    {
        stateLock.lock()
        diskEntryRecords[record.primaryURL] = record
        recentAccessDates[record.primaryURL] = record.lastAccessDate
        persistedAccessDates[record.primaryURL] = record.lastAccessDate
        stateLock.unlock()
    }

    @inlinable
    internal func recordAccess(
        at url: URL,
        date: Date,
        minimumPersistenceInterval: TimeInterval
    ) -> Bool
    {
        stateLock.lock()
        defer { stateLock.unlock() }

        recentAccessDates[url] = max(
            recentAccessDates[url] ?? .distantPast,
            date
        )
        if var record = diskEntryRecords[url]
        {
            record.lastAccessDate = max(record.lastAccessDate, date)
            diskEntryRecords[url] = record
        }
        let lastPersistedDate = persistedAccessDates[url] ?? .distantPast
        guard date.timeIntervalSince(lastPersistedDate)
            >= minimumPersistenceInterval else { return false }

        persistedAccessDates[url] = date
        return true
    }

    @inlinable
    internal func recentAccessDate(for url: URL) -> Date?
    {
        stateLock.lock()
        defer { stateLock.unlock() }
        return recentAccessDates[url]
    }

    @inlinable
    internal func forgetAccess(to url: URL)
    {
        stateLock.lock()
        recentAccessDates[url] = nil
        persistedAccessDates[url] = nil
        diskEntryRecords[url] = nil
        stateLock.unlock()
    }

    @inlinable
    internal func forgetDiskEntries(in directory: URL)
    {
        let prefix = directory.standardizedFileURL.path + "/"
        stateLock.lock()
        let removedRecords = diskEntryRecords.values.filter {
            $0.primaryURL.standardizedFileURL.path.hasPrefix(prefix)
        }
        for record in removedRecords
        {
            diskEntryRecords[record.primaryURL] = nil
            for url in record.relatedURLs
            {
                recentAccessDates[url] = nil
                persistedAccessDates[url] = nil
            }
        }
        stateLock.unlock()
    }

    @inlinable
    internal func indexedDiskEntries() -> [P_CacheDiskEntryRecord]?
    {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard diskEntryIndexIsComplete else { return nil }
        return Array(diskEntryRecords.values)
    }

    @inlinable
    internal func diskEntryIndexState() -> (isComplete: Bool, generation: UInt64)
    {
        stateLock.lock()
        defer { stateLock.unlock() }
        return (diskEntryIndexIsComplete, diskEntryIndexGeneration)
    }

    @inlinable
    internal func automaticMaintenanceState() -> (
        isScheduled: Bool,
        needsRecheck: Bool
    )
    {
        stateLock.lock()
        defer { stateLock.unlock() }
        return (
            automaticMaintenanceIsScheduled,
            automaticMaintenanceNeedsRecheck
        )
    }

    @inlinable
    internal func replaceDiskEntryIndex(
        _ records: [P_CacheDiskEntryRecord]
    )
    {
        stateLock.lock()
        diskEntryRecords = Dictionary(
            uniqueKeysWithValues: records.map {
                ($0.primaryURL, $0)
            }
        )
        diskEntryIndexIsComplete = true
        diskEntryIndexGeneration &+= 1
        totalCapacity = records.reduce(into: UInt64(0)) { result, record in
            let (sum, overflow) = result.addingReportingOverflow(
                record.capacity
            )
            result = overflow ? .max : sum
        }
        p_rearmAutomaticCapacityTriggers()
        stateLock.unlock()
    }

    @inlinable
    internal func replaceState(
        totalCapacity: UInt64,
        lastMaintenanceDate: Date
    )
    {
        stateLock.lock()
        self.totalCapacity = totalCapacity
        self.lastMaintenanceDate = lastMaintenanceDate
        if totalCapacity == 0
        {
            recentAccessDates.removeAll(keepingCapacity: true)
            persistedAccessDates.removeAll(keepingCapacity: true)
            diskEntryRecords.removeAll(keepingCapacity: true)
            diskEntryIndexIsComplete = true
        }
        p_rearmAutomaticCapacityTriggers()
        stateLock.unlock()
    }

    @inlinable
    internal func markMaintenanceCompleted(at date: Date)
    {
        stateLock.lock()
        lastMaintenanceDate = date
        stateLock.unlock()
    }

    @inlinable
    internal func beginAutomaticMaintenanceIfNeeded(
        capacityPolicy: CacheCapacityPolicy,
        minimumInterval: TimeInterval,
        now: Date
    ) -> P_CacheAutomaticMaintenanceReason?
    {
        stateLock.lock()
        defer { stateLock.unlock() }

        automaticPreferredCapacity = capacityPolicy.preferredCapacity
        automaticMaximumCapacity = capacityPolicy.maximumCapacity
        let exceedsPreferred = capacityPolicy.preferredCapacity.map {
            totalCapacity > $0
        } ?? false
        let exceedsMaximum = capacityPolicy.maximumCapacity.map {
            totalCapacity > $0
        } ?? false
        if !exceedsPreferred { preferredCapacityTriggerIsArmed = true }
        if !exceedsMaximum { maximumCapacityTriggerIsArmed = true }

        guard !automaticMaintenanceIsScheduled else
        {
            automaticMaintenanceNeedsRecheck = true
            return nil
        }
        let intervalElapsed = now.timeIntervalSince(lastMaintenanceDate)
            >= minimumInterval

        let reason: P_CacheAutomaticMaintenanceReason
        if intervalElapsed
        {
            reason = .reconciliation
        }
        else if exceedsMaximum && maximumCapacityTriggerIsArmed
        {
            reason = .capacity
        }
        else if exceedsPreferred && preferredCapacityTriggerIsArmed
        {
            reason = .capacity
        }
        else
        {
            return nil
        }

        if exceedsPreferred { preferredCapacityTriggerIsArmed = false }
        if exceedsMaximum { maximumCapacityTriggerIsArmed = false }
        automaticMaintenanceIsScheduled = true
        return reason
    }

    /// Rearms a crossed edge when maintenance actually reaches its lower side.
    ///
    /// This is evaluated on capacity mutation rather than only on a later
    /// request. Writes can otherwise carry capacity back above the watermark
    /// while a pass is still scheduled, hiding the below-to-above transition
    /// that requires one follow-up pass.
    @inlinable
    internal func p_rearmAutomaticCapacityTriggers()
    {
        if automaticPreferredCapacity.map({ totalCapacity <= $0 }) == true
        {
            preferredCapacityTriggerIsArmed = true
        }
        if automaticMaximumCapacity.map({ totalCapacity <= $0 }) == true
        {
            maximumCapacityTriggerIsArmed = true
        }
    }

    @inlinable
    @discardableResult
    internal func endAutomaticMaintenance() -> Bool
    {
        stateLock.lock()
        let needsRecheck = automaticMaintenanceNeedsRecheck
        automaticMaintenanceIsScheduled = false
        automaticMaintenanceNeedsRecheck = false
        stateLock.unlock()
        return needsRecheck
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_CacheWeakDiskDirectoryCoordinator
{
    @usableFromInline internal weak var value: P_CacheDiskDirectoryCoordinator?

    @inlinable
    internal init(_ value: P_CacheDiskDirectoryCoordinator)
    {
        self.value = value
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal enum P_CacheDiskDirectoryRegistry
{
    @usableFromInline internal static let lock = NSLock()
    @usableFromInline
    nonisolated(unsafe) internal static var coordinators: [
        String: P_CacheWeakDiskDirectoryCoordinator
    ] = [:]

    @inlinable
    internal static func coordinator(
        for directory: URL,
        initialCapacity: UInt64
    ) -> P_CacheDiskDirectoryCoordinator
    {
        let path = directory
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path

        lock.lock()
        defer { lock.unlock() }

        if let coordinator = coordinators[path]?.value
        {
            return coordinator
        }

        coordinators = coordinators.filter { $0.value.value != nil }
        let coordinator = P_CacheDiskDirectoryCoordinator(
            totalCapacity: initialCapacity
        )
        coordinators[path] = P_CacheWeakDiskDirectoryCoordinator(coordinator)
        return coordinator
    }
}
