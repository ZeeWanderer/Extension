//
//  P_DiskCacheStorageMaintenance.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_DiskCacheStorageMaintenance: @unchecked Sendable
{
    @usableFromInline
    internal struct ObjectMetadata: Codable
    {
        @usableFromInline internal let version: Int
        @usableFromInline internal let storedAt: Date
        @usableFromInline internal let expirationDate: Date?
        @usableFromInline internal let cost: Int
        @usableFromInline internal let payloadSize: Int
    }

    @usableFromInline
    internal typealias Record = P_CacheDiskEntryRecord

    @usableFromInline
    internal enum Requirement: Hashable, Sendable
    {
        case none
        case capacity
        case reconciliation
    }

    @usableFromInline
    internal enum RecordSource: Sendable
    {
        case object(URL)
        case sparse(data: URL, manifest: URL, manifestExists: Bool)
        case invalid(URL)
    }

    @usableFromInline
    internal struct RemovalSummary: Sendable
    {
        @usableFromInline internal var count = 0
        @usableFromInline internal var capacity: UInt64 = 0

        @inlinable
        internal init(count: Int = 0, capacity: UInt64 = 0)
        {
            self.count = count
            self.capacity = capacity
        }
    }

    @usableFromInline
    internal struct CapacitySummary: Sendable
    {
        @usableFromInline
        internal let plan: CacheCapacityPolicy.EvictionPlan<URL>
        @usableFromInline internal let removed: RemovalSummary

        @inlinable
        internal init(
            plan: CacheCapacityPolicy.EvictionPlan<URL>,
            removed: RemovalSummary
        )
        {
            self.plan = plan
            self.removed = removed
        }
    }

    @usableFromInline
    internal enum RemovalOutcome: @unchecked Sendable
    {
        case removed(UInt64)
        case kept
        case absent
        case failure(any Error)
    }

    @usableFromInline internal let directory: URL
    @usableFromInline internal let capacityPolicy: CacheCapacityPolicy
    @usableFromInline internal let minimumMaintenanceInterval: TimeInterval
    @usableFromInline internal let maximumUnusedInterval: TimeInterval?
    @usableFromInline internal let removesExpiredEntries: Bool
    @usableFromInline internal let performsAutomaticMaintenance: Bool
    @usableFromInline internal let maximumConcurrentOperations: Int
    @usableFromInline internal let fileManager: FileManager
    @usableFromInline internal let coordinator: P_CacheDiskDirectoryCoordinator
    @usableFromInline internal let ioExecutor: P_CacheIOExecutor

    @inlinable
    internal init(
        directory: URL,
        capacityPolicy: CacheCapacityPolicy,
        minimumMaintenanceInterval: TimeInterval,
        maximumUnusedInterval: TimeInterval?,
        removesExpiredEntries: Bool,
        performsAutomaticMaintenance: Bool,
        maximumConcurrentOperations: Int,
        fileManager: FileManager,
        coordinator: P_CacheDiskDirectoryCoordinator,
        ioExecutor: P_CacheIOExecutor
    )
    {
        self.directory = directory
        self.capacityPolicy = capacityPolicy
        self.minimumMaintenanceInterval = minimumMaintenanceInterval
        self.maximumUnusedInterval = maximumUnusedInterval
        self.removesExpiredEntries = removesExpiredEntries
        self.performsAutomaticMaintenance = performsAutomaticMaintenance
        self.maximumConcurrentOperations = maximumConcurrentOperations
        self.fileManager = fileManager
        self.coordinator = coordinator
        self.ioExecutor = ioExecutor
    }

    @inlinable
    internal func requestAutomaticMaintenance()
    {
        guard performsAutomaticMaintenance else { return }
        let now = Date.now
        guard coordinator.beginAutomaticMaintenanceIfNeeded(
            capacityPolicy: capacityPolicy,
            minimumInterval: minimumMaintenanceInterval,
            now: now
        ) != nil else { return }

        Task.detached(priority: .utility) { [self] in
            do
            {
                _ = try await perform(.ifNeeded)
                let needsRecheck = coordinator.endAutomaticMaintenance()
                // A mutation can request maintenance after the pass's final
                // capacity snapshot but before the scheduled flag is cleared.
                // Recheck only when such a request was observed, preventing a
                // zero interval from self-scheduling an idle maintenance loop.
                if needsRecheck { requestAutomaticMaintenance() }
            }
            catch
            {
                coordinator.endAutomaticMaintenance()
            }
        }
    }

    @inlinable
    internal func maintenanceIsNeeded(
        _ mode: CacheMaintenanceMode,
        at date: Date
    ) -> Bool
    {
        maintenanceRequirement(mode, at: date) != .none
    }

    @inlinable
    internal func maintenanceRequirement(
        _ mode: CacheMaintenanceMode,
        at date: Date
    ) -> Requirement
    {
        guard mode == .ifNeeded else { return .reconciliation }
        let state = coordinator.state()
        let reconciliationIsDue = date.timeIntervalSince(
            state.lastMaintenanceDate
        ) >= minimumMaintenanceInterval
        if reconciliationIsDue { return .reconciliation }
        let exceedsPreferred = capacityPolicy.preferredCapacity.map {
            state.totalCapacity > $0
        } ?? false
        return exceedsPreferred ? .capacity : .none
    }

    @inlinable
    internal func perform(
        _ mode: CacheMaintenanceMode
    ) async throws -> CacheStoreMaintenanceResult
    {
        let now = Date.now
        let initialRequirement = maintenanceRequirement(mode, at: now)
        guard initialRequirement != .none else
        {
            return .skipped(
                capacityUnit: .bytes,
                remainingCapacity: coordinator.state().totalCapacity
            )
        }

        try Task.checkCancellation()
        await coordinator.maintenanceGate.acquire(.write)
        if Task.isCancelled
        {
            coordinator.maintenanceGate.release(.write)
            throw CancellationError()
        }
        do
        {
            let requirement = maintenanceRequirement(mode, at: now)
            guard requirement != .none else
            {
                coordinator.maintenanceGate.release(.write)
                return .skipped(
                    capacityUnit: .bytes,
                    remainingCapacity: coordinator.state().totalCapacity
                )
            }
            let result = try await performPass(
                requirement: requirement,
                mode: mode,
                at: now
            )
            coordinator.maintenanceGate.release(.write)
            return result
        }
        catch
        {
            coordinator.maintenanceGate.release(.write)
            throw error
        }
    }

    @inlinable
    internal func performSynchronously(
        _ mode: CacheMaintenanceMode
    ) throws -> CacheStoreMaintenanceResult
    {
        let now = Date.now
        let initialRequirement = maintenanceRequirement(mode, at: now)
        guard initialRequirement != .none else
        {
            return .skipped(
                capacityUnit: .bytes,
                remainingCapacity: coordinator.state().totalCapacity
            )
        }

        coordinator.maintenanceGate.acquire(.write)
        defer { coordinator.maintenanceGate.release(.write) }
        let requirement = maintenanceRequirement(mode, at: now)
        guard requirement != .none else
        {
            return .skipped(
                capacityUnit: .bytes,
                remainingCapacity: coordinator.state().totalCapacity
            )
        }
        return try performPassSynchronously(
            requirement: requirement,
            mode: mode,
            at: now
        )
    }

    @inlinable
    internal func performPass(
        requirement: Requirement,
        mode: CacheMaintenanceMode,
        at now: Date
    ) async throws -> CacheStoreMaintenanceResult
    {
        if requirement == .capacity,
           let indexedRecords = coordinator.indexedDiskEntries()
        {
            let capacity = try await evictIndexedCapacity(
                mode: mode,
                at: now
            )
            let finalRecords = coordinator.indexedDiskEntries() ?? []
            return result(
                initialCount: indexedRecords.count,
                finalCount: finalRecords.count,
                finalCapacity: coordinator.state().totalCapacity,
                removed: capacity.removed,
                plan: capacity.plan
            )
        }

        return try await performReconciliationPass(mode: mode, at: now)
    }

    @inlinable
    internal func performPassSynchronously(
        requirement: Requirement,
        mode: CacheMaintenanceMode,
        at now: Date
    ) throws -> CacheStoreMaintenanceResult
    {
        if requirement == .capacity,
           let indexedRecords = coordinator.indexedDiskEntries()
        {
            let capacity = try evictIndexedCapacitySynchronously(
                mode: mode,
                at: now
            )
            let finalRecords = coordinator.indexedDiskEntries() ?? []
            return result(
                initialCount: indexedRecords.count,
                finalCount: finalRecords.count,
                finalCapacity: coordinator.state().totalCapacity,
                removed: capacity.removed,
                plan: capacity.plan
            )
        }

        return try performReconciliationPassSynchronously(
            mode: mode,
            at: now
        )
    }

    @inlinable
    internal func performReconciliationPass(
        mode: CacheMaintenanceMode,
        at now: Date
    ) async throws -> CacheStoreMaintenanceResult
    {
        try Task.checkCancellation()
        await coordinator.accessGate.acquire(.write)
        let initialRecords: [Record]
        do
        {
            initialRecords = try await records(at: now)
            coordinator.replaceDiskEntryIndex(initialRecords)
            coordinator.accessGate.release(.write)
        }
        catch
        {
            coordinator.accessGate.release(.write)
            throw error
        }

        await coordinator.accessGate.acquire(.read)
        var removed: RemovalSummary
        do
        {
            removed = try await remove(
                initialRecords.filter { shouldRemove($0, at: now) },
                recheckingStalenessAt: now
            )
            coordinator.accessGate.release(.read)
        }
        catch
        {
            coordinator.accessGate.release(.read)
            throw error
        }

        let capacity = capacityPolicy.isUnlimited
            ? emptyCapacitySummary(at: now)
            : try await evictIndexedCapacity(mode: mode, at: now)
        removed.count += capacity.removed.count
        removed.capacity = Self.saturatingSum(
            removed.capacity,
            capacity.removed.capacity
        )
        coordinator.markMaintenanceCompleted(at: now)
        let finalRecords = coordinator.indexedDiskEntries() ?? []
        return result(
            initialCount: initialRecords.count,
            finalCount: finalRecords.count,
            finalCapacity: coordinator.state().totalCapacity,
            removed: removed,
            plan: capacity.plan
        )
    }

    @inlinable
    internal func performReconciliationPassSynchronously(
        mode: CacheMaintenanceMode,
        at now: Date
    ) throws -> CacheStoreMaintenanceResult
    {
        coordinator.accessGate.acquire(.write)
        let initialRecords: [Record]
        do
        {
            initialRecords = try recordsSynchronously(at: now)
            coordinator.replaceDiskEntryIndex(initialRecords)
            coordinator.accessGate.release(.write)
        }
        catch
        {
            coordinator.accessGate.release(.write)
            throw error
        }

        coordinator.accessGate.acquire(.read)
        var removed: RemovalSummary
        do
        {
            removed = try removeSynchronously(
                initialRecords.filter { shouldRemove($0, at: now) },
                recheckingStalenessAt: now
            )
            coordinator.accessGate.release(.read)
        }
        catch
        {
            coordinator.accessGate.release(.read)
            throw error
        }

        let capacity = capacityPolicy.isUnlimited
            ? emptyCapacitySummary(at: now)
            : try evictIndexedCapacitySynchronously(
                mode: mode,
                at: now
            )
        removed.count += capacity.removed.count
        removed.capacity = Self.saturatingSum(
            removed.capacity,
            capacity.removed.capacity
        )
        coordinator.markMaintenanceCompleted(at: now)
        let finalRecords = coordinator.indexedDiskEntries() ?? []
        return result(
            initialCount: initialRecords.count,
            finalCount: finalRecords.count,
            finalCapacity: coordinator.state().totalCapacity,
            removed: removed,
            plan: capacity.plan
        )
    }

    @inlinable
    internal func evictIndexedCapacity(
        mode: CacheMaintenanceMode,
        at now: Date
    ) async throws -> CapacitySummary
    {
        try Task.checkCancellation()
        await coordinator.accessGate.acquire(.write)
        do
        {
            let records = coordinator.indexedDiskEntries() ?? []
            let plan = evictionPlan(
                records.filter { !$0.isInvalid },
                mode: mode,
                at: now
            )
            let byURL = Dictionary(
                uniqueKeysWithValues: records.map { ($0.primaryURL, $0) }
            )
            let removed = try await remove(
                plan.evictions.compactMap { byURL[$0.id] },
                recheckingStalenessAt: nil
            )
            coordinator.accessGate.release(.write)
            return CapacitySummary(plan: plan, removed: removed)
        }
        catch
        {
            coordinator.accessGate.release(.write)
            throw error
        }
    }

    @inlinable
    internal func evictIndexedCapacitySynchronously(
        mode: CacheMaintenanceMode,
        at now: Date
    ) throws -> CapacitySummary
    {
        coordinator.accessGate.acquire(.write)
        do
        {
            let records = coordinator.indexedDiskEntries() ?? []
            let plan = evictionPlan(
                records.filter { !$0.isInvalid },
                mode: mode,
                at: now
            )
            let byURL = Dictionary(
                uniqueKeysWithValues: records.map { ($0.primaryURL, $0) }
            )
            let removed = try removeSynchronously(
                plan.evictions.compactMap { byURL[$0.id] },
                recheckingStalenessAt: nil
            )
            coordinator.accessGate.release(.write)
            return CapacitySummary(plan: plan, removed: removed)
        }
        catch
        {
            coordinator.accessGate.release(.write)
            throw error
        }
    }

    @inlinable
    internal func emptyCapacitySummary(at date: Date) -> CapacitySummary
    {
        let candidates: [CacheCapacityPolicy.Candidate<URL>] = []
        return CapacitySummary(
            plan: capacityPolicy.evictionPlan(
                currentCapacity: coordinator.state().totalCapacity,
                candidates: candidates,
                at: date
            ),
            removed: RemovalSummary()
        )
    }

    @inlinable
    internal func removeAll() async throws
    {
        try Task.checkCancellation()
        await coordinator.accessGate.acquire(.write)
        if Task.isCancelled
        {
            coordinator.accessGate.release(.write)
            throw CancellationError()
        }
        do
        {
            try await ioExecutor.run { try self.removeAllFiles() }
            coordinator.accessGate.release(.write)
        }
        catch
        {
            coordinator.accessGate.release(.write)
            throw error
        }
    }

    @inlinable
    internal func removeAllSynchronously() throws
    {
        coordinator.accessGate.acquire(.write)
        defer { coordinator.accessGate.release(.write) }
        try removeAllFiles()
    }

    @inlinable
    internal func removeAllFiles() throws
    {
        coordinator.sparseResources.invalidateAll()
        if fileManager.fileExists(atPath: directory.path)
        {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        coordinator.replaceState(
            totalCapacity: 0,
            lastMaintenanceDate: .now
        )
    }

    @usableFromInline
    internal func records(at now: Date) async throws -> [Record]
    {
        let sources = try await ioExecutor.run {
            try self.recordSources()
        }
        guard !sources.isEmpty else { return [] }

        let limit = min(maximumConcurrentOperations, sources.count)
        let batchSize = (sources.count + limit - 1) / limit
        return try await withThrowingTaskGroup(
            of: [(Int, Record)].self,
            returning: [Record].self
        ) { group in
            for startIndex in stride(
                from: 0,
                to: sources.count,
                by: batchSize
            )
            {
                let endIndex = min(startIndex + batchSize, sources.count)
                group.addTask {
                    try await self.ioExecutor.run {
                        var records: [(Int, Record)] = []
                        records.reserveCapacity(endIndex - startIndex)
                        for index in startIndex..<endIndex
                        {
                            try Task.checkCancellation()
                            records.append((
                                index,
                                self.record(from: sources[index], at: now)
                            ))
                        }
                        return records
                    }
                }
            }

            var records = [Record?](repeating: nil, count: sources.count)
            for try await batch in group
            {
                for (index, record) in batch
                {
                    records[index] = record
                }
            }
            return records.compactMap { $0 }
        }
    }

    @usableFromInline
    internal func recordsSynchronously(at now: Date) throws -> [Record]
    {
        try recordSources().map { record(from: $0, at: now) }
    }

    @usableFromInline
    internal func recordSources() throws -> [RecordSource]
    {
        let urls = regularFileURLs()
        let urlSet = Set(urls)
        var consumed: Set<URL> = []
        var result: [RecordSource] = []
        result.reserveCapacity(urls.count)
        for url in urls where !consumed.contains(url)
        {
            switch url.pathExtension
            {
            case "sparsecache":
                let manifestURL = url.deletingPathExtension()
                    .appendingPathExtension("sparsemeta")
                consumed.insert(url)
                consumed.insert(manifestURL)
                result.append(.sparse(
                    data: url,
                    manifest: manifestURL,
                    manifestExists: urlSet.contains(manifestURL)
                ))
            case "sparsemeta":
                let dataURL = url.deletingPathExtension()
                    .appendingPathExtension("sparsecache")
                consumed.insert(url)
                if urlSet.contains(dataURL)
                {
                    consumed.insert(dataURL)
                    result.append(.sparse(
                        data: dataURL,
                        manifest: url,
                        manifestExists: true
                    ))
                }
                else
                {
                    result.append(.invalid(url))
                }
            case "cache":
                consumed.insert(url)
                result.append(.object(url))
            default:
                consumed.insert(url)
                result.append(.invalid(url))
            }
        }
        return result
    }

    @usableFromInline
    internal func regularFileURLs() -> [URL]
    {
        var pendingDirectories = [directory]
        var urls: [URL] = []
        while let currentDirectory = pendingDirectories.popLast()
        {
            let children = (try? fileManager.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                ],
                options: [.skipsHiddenFiles]
            )) ?? []
            for enumeratedURL in children
            {
                let pathExtension = enumeratedURL.pathExtension
                if pathExtension == "cache"
                    || pathExtension == "sparsecache"
                    || pathExtension == "sparsemeta"
                {
                    // These are library-owned entries in an exclusively owned
                    // directory. Unknown entries take the defensive metadata
                    // path below before they are traversed or removed.
                    urls.append(currentDirectory.appendingPathComponent(
                        enumeratedURL.lastPathComponent,
                        isDirectory: false
                    ))
                }
                else if pathExtension == "sparse"
                {
                    let values = try? enumeratedURL.resourceValues(forKeys: [
                        .isDirectoryKey,
                        .isSymbolicLinkKey,
                    ])
                    let isDirectory = values?.isDirectory == true
                        && values?.isSymbolicLink != true
                    let url = currentDirectory.appendingPathComponent(
                        enumeratedURL.lastPathComponent,
                        isDirectory: isDirectory
                    )
                    if isDirectory
                    {
                        pendingDirectories.append(url)
                    }
                    else
                    {
                        // A namespace-shaped symlink or file is invalid cache
                        // data. Record the entry itself for removal without
                        // ever traversing beyond the owned storage directory.
                        urls.append(url)
                    }
                }
                else
                {
                    let values = try? enumeratedURL.resourceValues(forKeys: [
                        .isRegularFileKey,
                        .isDirectoryKey,
                        .isSymbolicLinkKey,
                    ])
                    guard values?.isSymbolicLink != true else { continue }
                    let isDirectory = values?.isDirectory == true
                    let url = currentDirectory.appendingPathComponent(
                        enumeratedURL.lastPathComponent,
                        isDirectory: isDirectory
                    )
                    if values?.isRegularFile == true
                    {
                        urls.append(url)
                    }
                    else if isDirectory
                    {
                        pendingDirectories.append(url)
                    }
                }
            }
        }
        return urls
    }

    @inlinable
    internal func record(
        from source: RecordSource,
        at now: Date
    ) -> Record
    {
        switch source
        {
        case let .object(url):
            objectRecord(url: url, now: now)
        case let .sparse(dataURL, manifestURL, manifestExists):
            sparseRecord(
                dataURL: dataURL,
                manifestURL: manifestURL,
                manifestExists: manifestExists,
                now: now
            )
        case let .invalid(url):
            invalidRecord(url: url, now: now)
        }
    }

    @usableFromInline
    internal func objectRecord(url: URL, now: Date) -> Record
    {
        let values = resourceValues(for: url)
        let originalAccessDate = p_tracksAccessDates
            ? values.contentAccessDate
            : nil
        defer
        {
            if p_tracksAccessDates
            {
                restoreAccessDate(originalAccessDate, to: url)
            }
        }

        let capacity = Self.fileCapacity(from: values)
        let fileSize = UInt64(max(0, values.fileSize ?? 0))
        let metadata = try? objectMetadata(at: url, fileSize: fileSize)
        let fallbackAccessDate = metadata?.storedAt ?? .distantPast
        let lastAccessDate = p_tracksAccessDates
            ? resolvedAccessDate(
                primaryURL: url,
                values: values,
                fallback: fallbackAccessDate
            )
            : fallbackAccessDate
        return Record(
            primaryURL: url,
            relatedURLs: [url],
            capacity: capacity,
            lastAccessDate: lastAccessDate,
            expirationDate: metadata?.expirationDate,
            isInvalid: metadata == nil,
            isSparse: false
        )
    }

    @usableFromInline
    internal func sparseRecord(
        dataURL: URL,
        manifestURL: URL,
        manifestExists: Bool,
        now: Date
    ) -> Record
    {
        let dataValues = resourceValues(for: dataURL)
        let manifestValues = resourceValues(for: manifestURL)
        let originalDataAccessDate = p_tracksAccessDates
            ? dataValues.contentAccessDate
            : nil
        let originalManifestAccessDate = p_tracksAccessDates
            ? manifestValues.contentAccessDate
            : nil
        defer
        {
            if p_tracksAccessDates
            {
                restoreAccessDate(originalDataAccessDate, to: dataURL)
                restoreAccessDate(originalManifestAccessDate, to: manifestURL)
            }
        }

        let manifest = manifestExists
            ? (try? sparseManifest(at: manifestURL))
            : nil
        let dataSize = dataValues.fileSize ?? -1
        let isValid = manifest?.isValid == true
            && dataSize == manifest?.capacity
        let capacity = Self.saturatingSum(
            Self.fileCapacity(from: dataValues),
            Self.fileCapacity(from: manifestValues)
        )
        let fallbackAccessDate = manifest?.storedAt ?? .distantPast
        let lastAccessDate = p_tracksAccessDates
            ? max(
                resolvedAccessDate(
                    primaryURL: dataURL,
                    values: dataValues,
                    fallback: fallbackAccessDate
                ),
                manifestValues.contentModificationDate ?? .distantPast
            )
            : fallbackAccessDate
        return Record(
            primaryURL: dataURL,
            relatedURLs: [dataURL, manifestURL],
            capacity: capacity,
            lastAccessDate: lastAccessDate,
            expirationDate: manifest?.expirationDate,
            isInvalid: !isValid,
            isSparse: true
        )
    }

    @usableFromInline
    internal func invalidRecord(url: URL, now: Date) -> Record
    {
        let values = resourceValues(for: url)
        return Record(
            primaryURL: url,
            relatedURLs: [url],
            capacity: Self.fileCapacity(from: values),
            lastAccessDate: p_tracksAccessDates
                ? resolvedAccessDate(
                    primaryURL: url,
                    values: values,
                    fallback: .distantPast
                )
                : .distantPast,
            expirationDate: nil,
            isInvalid: true,
            isSparse: false
        )
    }

    @usableFromInline
    internal func objectMetadata(
        at url: URL,
        fileSize: UInt64
    ) throws -> ObjectMetadata
    {
        guard let fileSize = Int(exactly: fileSize), fileSize >= 4 else
        {
            throw CacheError.invalidDiskEntry
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let sizeData = try handle.read(upToCount: 4) ?? Data()
        guard sizeData.count == 4 else { throw CacheError.invalidDiskEntry }
        let metadataSize = sizeData.reduce(UInt32(0)) { result, byte in
            (result << 8) | UInt32(byte)
        }
        let count = Int(metadataSize)
        guard count <= fileSize - 4 else { throw CacheError.invalidDiskEntry }
        let data = try handle.read(upToCount: count) ?? Data()
        guard data.count == count else { throw CacheError.invalidDiskEntry }
        let metadata = try JSONDecoder().decode(ObjectMetadata.self, from: data)
        guard metadata.version == 1,
              metadata.payloadSize == fileSize - 4 - count else
        {
            throw CacheError.invalidDiskEntry
        }
        return metadata
    }

    @usableFromInline
    internal func sparseManifest(at url: URL) throws -> P_SparseCacheManifest
    {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(P_SparseCacheManifest.self, from: data)
    }

    @usableFromInline
    internal func remove(
        _ records: [Record],
        recheckingStalenessAt date: Date?
    ) async throws -> RemovalSummary
    {
        guard !records.isEmpty else { return RemovalSummary() }
        let limit = min(maximumConcurrentOperations, records.count)
        return try await withThrowingTaskGroup(
            of: RemovalOutcome.self,
            returning: RemovalSummary.self
        ) { group in
            var nextIndex = 0
            for _ in 0..<limit
            {
                let record = records[nextIndex]
                nextIndex += 1
                group.addTask {
                    await self.removeWithAccess(
                        record,
                        recheckingStalenessAt: date
                    )
                }
            }

            var summary = RemovalSummary()
            var firstFailure: (any Error)?
            for try await outcome in group
            {
                switch outcome
                {
                case let .removed(capacity):
                    summary.count += 1
                    summary.capacity = Self.saturatingSum(
                        summary.capacity,
                        capacity
                    )
                case .kept, .absent:
                    break
                case let .failure(error):
                    if firstFailure == nil { firstFailure = error }
                }
                if nextIndex < records.count
                {
                    let record = records[nextIndex]
                    nextIndex += 1
                    group.addTask {
                        await self.removeWithAccess(
                            record,
                            recheckingStalenessAt: date
                        )
                    }
                }
            }
            if let firstFailure { throw firstFailure }
            return summary
        }
    }

    @usableFromInline
    internal func removeWithAccess(
        _ record: Record,
        recheckingStalenessAt date: Date?
    ) async -> RemovalOutcome
    {
        let fileGate = coordinator.fileGates.retainGate(for: record.primaryURL)
        await fileGate.acquire(.write)
        if Task.isCancelled
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: record.primaryURL)
            return .failure(CancellationError())
        }
        let outcome: RemovalOutcome
        do
        {
            outcome = try await ioExecutor.run {
                try self.removeRecord(
                    record,
                    recheckingStalenessAt: date
                )
            }
        }
        catch
        {
            outcome = .failure(error)
        }
        fileGate.release(.write)
        coordinator.fileGates.releaseGate(fileGate, for: record.primaryURL)
        return outcome
    }

    @usableFromInline
    internal func removeSynchronously(
        _ records: [Record],
        recheckingStalenessAt date: Date?
    ) throws -> RemovalSummary
    {
        var summary = RemovalSummary()
        for record in records
        {
            let fileGate = coordinator.fileGates.retainGate(
                for: record.primaryURL
            )
            fileGate.acquire(.write)
            let outcome: RemovalOutcome
            do
            {
                outcome = try removeRecord(
                    record,
                    recheckingStalenessAt: date
                )
                fileGate.release(.write)
                coordinator.fileGates.releaseGate(
                    fileGate,
                    for: record.primaryURL
                )
            }
            catch
            {
                fileGate.release(.write)
                coordinator.fileGates.releaseGate(
                    fileGate,
                    for: record.primaryURL
                )
                throw error
            }
            switch outcome
            {
            case let .removed(capacity):
                summary.count += 1
                summary.capacity = Self.saturatingSum(
                    summary.capacity,
                    capacity
                )
            case .kept, .absent:
                break
            case let .failure(error):
                throw error
            }
        }
        return summary
    }

    @usableFromInline
    internal func removeRecord(
        _ record: Record,
        recheckingStalenessAt date: Date?
    ) throws -> RemovalOutcome
    {
        let existingURLs = record.relatedURLs.filter {
            fileManager.fileExists(atPath: $0.path)
        }
        guard !existingURLs.isEmpty else
        {
            for url in record.relatedURLs { coordinator.forgetAccess(to: url) }
            return .absent
        }
        if let date
        {
            let current = record.primaryURL.pathExtension == "sparsecache"
                ? sparseRecord(
                    dataURL: record.primaryURL,
                    manifestURL: record.primaryURL.deletingPathExtension()
                        .appendingPathExtension("sparsemeta"),
                    manifestExists: fileManager.fileExists(
                        atPath: record.primaryURL.deletingPathExtension()
                            .appendingPathExtension("sparsemeta").path
                    ),
                    now: date
                )
                : (record.primaryURL.pathExtension == "cache"
                    ? objectRecord(url: record.primaryURL, now: date)
                    : invalidRecord(url: record.primaryURL, now: date))
            guard shouldRemove(current, at: date) else
            {
                coordinator.recordStoredEntry(current)
                return .kept
            }
        }

        let oldCapacity = existingURLs.reduce(into: UInt64(0)) { result, url in
            result = Self.saturatingSum(result, fileCapacity(at: url))
        }
        for url in existingURLs
        {
            do { try fileManager.removeItem(at: url) }
            catch CocoaError.fileNoSuchFile {}
        }
        coordinator.updateTotalCapacity(from: oldCapacity, to: 0)
        for url in record.relatedURLs { coordinator.forgetAccess(to: url) }
        if record.isSparse
        {
            coordinator.sparseResources.invalidate(record.primaryURL)
        }
        return .removed(oldCapacity)
    }

    @inlinable
    internal func shouldRemove(_ record: Record, at now: Date) -> Bool
    {
        if record.isInvalid { return true }
        if removesExpiredEntries,
           record.expirationDate.map({ now >= $0 }) == true
        {
            return true
        }
        if let maximumUnusedInterval,
           now.timeIntervalSince(record.lastAccessDate) >= maximumUnusedInterval
        {
            return true
        }
        return false
    }

    @inlinable
    internal func evictionPlan(
        _ records: [Record],
        mode: CacheMaintenanceMode,
        at date: Date
    ) -> CacheCapacityPolicy.EvictionPlan<URL>
    {
        let candidates = records
            .sorted { $0.primaryURL.path < $1.primaryURL.path }
            .map {
                CacheCapacityPolicy.Candidate(
                    id: $0.primaryURL,
                    capacity: $0.capacity,
                    lastAccessDate: $0.lastAccessDate
                )
            }
        return capacityPolicy.evictionPlan(
            currentCapacity: coordinator.state().totalCapacity,
            candidates: candidates,
            at: date,
            allowsProtectedEviction: mode == .aggressive
        )
    }

    @inlinable
    internal func result(
        initialCount: Int,
        finalCount: Int,
        finalCapacity: UInt64,
        removed: RemovalSummary,
        plan: CacheCapacityPolicy.EvictionPlan<URL>
    ) -> CacheStoreMaintenanceResult
    {
        CacheStoreMaintenanceResult(
            status: .completed,
            scannedEntryCount: initialCount,
            removedEntryCount: removed.count,
            capacityUnit: .bytes,
            removedCapacity: removed.capacity,
            remainingEntryCount: finalCount,
            remainingCapacity: finalCapacity,
            protectedEntryCount: plan.protectedEntryCount,
            protectedCapacity: plan.protectedCapacity,
            didExceedMaximumCapacity: plan.didExceedMaximumCapacity
        )
    }

    @inlinable
    internal func resolvedAccessDate(
        primaryURL: URL,
        values: URLResourceValues,
        fallback: Date
    ) -> Date
    {
        max(
            max(
                values.contentAccessDate ?? .distantPast,
                values.contentModificationDate ?? fallback
            ),
            coordinator.recentAccessDate(for: primaryURL) ?? .distantPast
        )
    }

    @inlinable
    internal func resourceValues(for url: URL) -> URLResourceValues
    {
        let keys: Set<URLResourceKey> = p_tracksAccessDates
            ? [
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
                .contentAccessDateKey,
                .contentModificationDateKey,
            ]
            : [
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
            ]
        return (try? url.resourceValues(forKeys: keys))
            ?? URLResourceValues()
    }

    @inlinable
    internal var p_tracksAccessDates: Bool
    {
        maximumUnusedInterval != nil || !capacityPolicy.isUnlimited
    }

    @inlinable
    internal func restoreAccessDate(_ date: Date?, to url: URL)
    {
        guard let date else { return }
        var values = URLResourceValues()
        values.contentAccessDate = date
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }

    @inlinable
    internal func fileCapacity(at url: URL) -> UInt64
    {
        Self.fileCapacity(from: resourceValues(for: url))
    }

    @inlinable
    internal static func fileCapacity(
        from values: URLResourceValues
    ) -> UInt64
    {
        if let total = values.totalFileAllocatedSize
        {
            return UInt64(max(0, total))
        }
        if let allocated = values.fileAllocatedSize
        {
            return UInt64(max(0, allocated))
        }
        return UInt64(max(0, values.fileSize ?? 0))
    }

    @inlinable
    internal static func saturatingSum(_ lhs: UInt64, _ rhs: UInt64) -> UInt64
    {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? .max : sum
    }
}
