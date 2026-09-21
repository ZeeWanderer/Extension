//
//  SparseCache.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import CryptoKit
import Darwin
import Foundation

/// A persistent cache for independently available byte ranges of large data.
///
/// Reads may overlap other reads. Reads and writes to disjoint ranges may also
/// overlap, while any write excludes access to its intersecting bytes. Entry
/// preparation, removal, synchronization, and maintenance are whole-resource
/// barriers. Operations for different keys remain independent.
///
/// `generation` is deliberately caller-defined. Supplying the same generation
/// and logical capacity preserves existing ranges; changing either resets the
/// entry. An unversioned resource (`nil`) is assumed stable for its key and
/// capacity, so HTTP-backed callers should normally supply an ETag,
/// Last-Modified value, or another content version.
/// Bytes already available in one generation are immutable; overlapping inserts
/// write only missing gaps. Change the generation to replace cached content.
///
/// This is a separate typed facade rather than an ordinary ``CacheStore``:
/// partial byte availability cannot satisfy the full-value contract or generic
/// promotion rules of ``Cache``. Sharing ``DiskCacheStorage`` coordinates disk
/// capacity and maintenance, but does not imply that an object-cache value and
/// a sparse entry are coherent copies of the same logical resource.
///
/// Async operations leave the caller's actor without creating a separate task.
/// Blocking file I/O uses the storage's dedicated task executor. Debounced
/// manifest persistence is resource-owned work that can outlive an insert;
/// await `synchronize(forKey:)` when persistence must finish before returning.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public final class SparseCache<Key: Hashable & Sendable>: @unchecked Sendable
{
    @usableFromInline internal let p_storage: DiskCacheStorage
    @usableFromInline internal let p_configuration: SparseCacheConfiguration
    @usableFromInline internal let p_keyEncoder: CacheKeyEncoder<Key>
    @usableFromInline internal let p_directory: URL

    public init(
        storage: DiskCacheStorage,
        configuration: SparseCacheConfiguration = .init(),
        keyEncoder: CacheKeyEncoder<Key>
    ) throws
    {
        guard DiskCacheStorage.p_isValidDirectoryName(configuration.name) else
        {
            throw SparseCacheError.invalidConfiguration(
                "The sparse cache name must be a nonempty path component"
            )
        }
        if configuration.requiresSparseFileSupport
        {
            let values = try storage.directoryURL.resourceValues(forKeys: [
                .volumeSupportsSparseFilesKey,
            ])
            guard values.volumeSupportsSparseFiles == true else
            {
                throw SparseCacheError.sparseFilesUnsupported(
                    storage.directoryURL
                )
            }
        }

        let directory = storage.directoryURL.appending(
            component: "\(configuration.name).sparse",
            directoryHint: .isDirectory
        )
        try storage.p_fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        self.p_storage = storage
        self.p_configuration = configuration
        self.p_keyEncoder = keyEncoder
        self.p_directory = directory
    }

    // MARK: - Synchronous API

    /// Returns an immutable entry snapshot, blocking the caller.
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func snapshot(forKey key: Key) throws -> SparseCacheSnapshot?
    {
        try p_withResourceAccess(for: key, access: .metadataRead) { resource in
            guard let manifest = try resource.loadIfNeeded(
                fileManager: p_storage.p_fileManager
            ), manifest.expirationDate.map({ Date.now >= $0 }) != true else
            {
                return nil
            }
            p_recordAccess(to: resource.dataURL)
            return SparseCacheSnapshot(manifest)
        }
    }

    /// Creates or validates an entry, blocking the caller.
    ///
    /// Existing ranges survive only when capacity and generation both match.
    @discardableResult
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func prepare(
        capacity: Int,
        generation: Data? = nil,
        metadata: Data? = nil,
        expirationDate: Date? = nil,
        forKey key: Key
    ) throws -> SparseCacheSnapshot
    {
        guard capacity > 0 else { throw SparseCacheError.invalidCapacity }
        return try p_withResourceAccess(for: key, access: .wholeWrite) {
            try p_prepare(
                $0,
                capacity: capacity,
                generation: generation,
                metadata: metadata,
                expirationDate: expirationDate
            )
        }
    }

    /// Stores bytes at an offset in a prepared entry, blocking the caller.
    @discardableResult
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func insert(
        _ data: Data,
        at offset: Int,
        forKey key: Key
    ) throws -> SparseCacheSnapshot
    {
        let range = try Self.p_validatedRange(
            offset: offset,
            byteCount: data.count
        )
        return try p_withResourceAccess(for: key, access: .write(range)) {
            try p_insert(data, in: range, resource: $0)
        }
    }

    /// Returns a completely available byte range, blocking the caller.
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func data(
        in range: Range<Int>,
        forKey key: Key
    ) throws -> Data?
    {
        try Self.p_validate(range)
        return try p_withResourceAccess(for: key, access: .read(range)) {
            try p_read(range, resource: $0)
        }
    }

    /// Persists the latest manifest and synchronizes its files, blocking.
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func synchronize(forKey key: Key) throws
    {
        try p_withResourceAccess(for: key, access: .wholeWrite) { resource in
            resource.cancelFlushTask()
            try p_flushResource(resource)
            guard let (descriptor, _) = try? resource.descriptorAndManifest() else { return }
            guard Darwin.fsync(descriptor) == 0 else { throw Self.p_posixError() }
            let manifestDescriptor = Darwin.open(
                resource.manifestURL.path,
                O_RDONLY | O_CLOEXEC
            )
            guard manifestDescriptor >= 0 else { throw Self.p_posixError() }
            defer { Darwin.close(manifestDescriptor) }
            guard Darwin.fsync(manifestDescriptor) == 0 else
            {
                throw Self.p_posixError()
            }
        }
    }

    /// Removes one sparse entry, blocking the caller.
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func removeValue(forKey key: Key) throws
    {
        try p_withResourceAccess(for: key, access: .wholeWrite) {
            try p_remove($0)
        }
    }

    /// Removes this sparse namespace, blocking the caller.
    @available(*, noasync, message: "Use the async sparse cache API from an async context")
    public func removeAll() throws
    {
        p_storage.p_coordinator.accessGate.acquire(.write)
        defer
        {
            p_storage.p_coordinator.accessGate.release(.write)
            p_storage.p_requestAutomaticMaintenance()
        }
        try p_removeAllFiles()
    }

    // MARK: - Asynchronous API

    /// Returns an immutable entry snapshot without blocking the caller.
    @concurrent
    public func snapshot(forKey key: Key) async throws -> SparseCacheSnapshot?
    {
        try await p_withResourceAccess(
            for: key,
            access: .metadataRead
        ) { resource in
            try await self.p_storage.p_ioExecutor.run {
                guard let manifest = try resource.loadIfNeeded(
                    fileManager: self.p_storage.p_fileManager
                ), manifest.expirationDate.map({ Date.now >= $0 }) != true else { return nil }
                self.p_recordAccess(to: resource.dataURL)
                return SparseCacheSnapshot(manifest)
            }
        }
    }

    /// Creates or validates an entry without blocking the caller.
    @discardableResult
    @concurrent
    public func prepare(
        capacity: Int,
        generation: Data? = nil,
        metadata: Data? = nil,
        expirationDate: Date? = nil,
        forKey key: Key
    ) async throws -> SparseCacheSnapshot
    {
        guard capacity > 0 else { throw SparseCacheError.invalidCapacity }
        return try await p_withResourceAccess(
            for: key,
            access: .wholeWrite
        ) { resource in
            try await self.p_storage.p_ioExecutor.run {
                try self.p_prepare(
                    resource,
                    capacity: capacity,
                    generation: generation,
                    metadata: metadata,
                    expirationDate: expirationDate
                )
            }
        }
    }

    /// Stores bytes at an offset without blocking the caller.
    @discardableResult
    @concurrent
    public func insert(
        _ data: Data,
        at offset: Int,
        forKey key: Key
    ) async throws -> SparseCacheSnapshot
    {
        let range = try Self.p_validatedRange(
            offset: offset,
            byteCount: data.count
        )
        return try await p_withResourceAccess(
            for: key,
            access: .write(range)
        ) { resource in
            try await self.p_storage.p_ioExecutor.run {
                try self.p_insert(data, in: range, resource: resource)
            }
        }
    }

    /// Returns a completely available byte range without blocking the caller.
    @concurrent
    public func data(
        in range: Range<Int>,
        forKey key: Key
    ) async throws -> Data?
    {
        try Self.p_validate(range)
        return try await p_withResourceAccess(
            for: key,
            access: .read(range)
        ) { resource in
            try await self.p_storage.p_ioExecutor.run {
                try self.p_read(range, resource: resource)
            }
        }
    }

    /// Persists the latest manifest and synchronizes its files asynchronously.
    @concurrent
    public func synchronize(forKey key: Key) async throws
    {
        try await p_withResourceAccess(
            for: key,
            access: .wholeWrite
        ) { resource in
            resource.cancelFlushTask()
            try await self.p_storage.p_ioExecutor.run {
                try self.p_flushResource(resource)
                guard let (descriptor, _) = try? resource.descriptorAndManifest() else { return }
                guard Darwin.fsync(descriptor) == 0 else
                {
                    throw Self.p_posixError()
                }
                let manifestDescriptor = Darwin.open(
                    resource.manifestURL.path,
                    O_RDONLY | O_CLOEXEC
                )
                guard manifestDescriptor >= 0 else
                {
                    throw Self.p_posixError()
                }
                defer { Darwin.close(manifestDescriptor) }
                guard Darwin.fsync(manifestDescriptor) == 0 else
                {
                    throw Self.p_posixError()
                }
            }
        }
    }

    /// Removes one sparse entry without blocking the caller.
    @concurrent
    public func removeValue(forKey key: Key) async throws
    {
        try await p_withResourceAccess(
            for: key,
            access: .wholeWrite
        ) { resource in
            try await self.p_storage.p_ioExecutor.run {
                try self.p_remove(resource)
            }
        }
    }

    /// Removes this sparse namespace without blocking the caller.
    @concurrent
    public func removeAll() async throws
    {
        try Task.checkCancellation()
        await p_storage.p_coordinator.accessGate.acquire(.write)
        if Task.isCancelled
        {
            p_storage.p_coordinator.accessGate.release(.write)
            throw CancellationError()
        }
        do
        {
            try await p_storage.p_ioExecutor.run { try self.p_removeAllFiles() }
            p_storage.p_coordinator.accessGate.release(.write)
            p_storage.p_requestAutomaticMaintenance()
        }
        catch
        {
            p_storage.p_coordinator.accessGate.release(.write)
            p_storage.p_requestAutomaticMaintenance()
            throw error
        }
    }

    // MARK: - Operations under resource access

    @usableFromInline
    internal func p_prepare(
        _ resource: P_SparseCacheResource,
        capacity: Int,
        generation: Data?,
        metadata: Data?,
        expirationDate: Date?
    ) throws -> SparseCacheSnapshot
    {
        let fileManager = p_storage.p_fileManager
        let existing: P_SparseCacheManifest?
        do
        {
            existing = try resource.loadIfNeeded(fileManager: fileManager)
        }
        catch SparseCacheError.invalidEntry
        {
            resource.invalidate()
            existing = nil
        }

        if let existing,
           existing.capacity == capacity,
           existing.generation == generation,
           existing.expirationDate.map({ Date.now >= $0 }) != true
        {
            if existing.metadata != metadata
                || existing.expirationDate != expirationDate
            {
                let (updated, _) = try resource.updateManifest {
                    $0.metadata = metadata
                    $0.expirationDate = expirationDate
                }
                p_recordStoredResource(resource, manifest: updated)
                p_scheduleFlush(resource)
                return SparseCacheSnapshot(updated)
            }
            p_recordStoredResource(resource, manifest: existing)
            return SparseCacheSnapshot(existing)
        }

        resource.cancelFlushTask()
        let oldCapacity = p_capacity(of: resource)
        resource.invalidate()
        try p_removeFileIfPresent(resource.dataURL)
        try p_removeFileIfPresent(resource.manifestURL)
        try fileManager.createDirectory(
            at: p_directory,
            withIntermediateDirectories: true
        )

        let descriptor = Darwin.open(
            resource.dataURL.path,
            O_RDWR | O_CREAT | O_EXCL | O_CLOEXEC,
            S_IRUSR | S_IWUSR
        )
        guard descriptor >= 0 else { throw Self.p_posixError() }
        var descriptorMustClose = true
        defer
        {
            if descriptorMustClose { Darwin.close(descriptor) }
        }
        guard Darwin.ftruncate(descriptor, off_t(capacity)) == 0 else
        {
            throw Self.p_posixError()
        }

        let manifest = P_SparseCacheManifest(
            version: 1,
            capacity: capacity,
            ranges: [],
            generation: generation,
            metadata: metadata,
            storedAt: .now,
            expirationDate: expirationDate
        )
        do
        {
            try p_writeManifest(manifest, to: resource.manifestURL)
        }
        catch
        {
            try? fileManager.removeItem(at: resource.dataURL)
            throw error
        }
        let newCapacity = p_capacity(of: resource)
        resource.replace(
            manifest: manifest,
            fileDescriptor: descriptor,
            accountedCapacity: newCapacity
        )
        descriptorMustClose = false
        p_storage.p_coordinator.updateTotalCapacity(
            from: oldCapacity,
            to: newCapacity
        )
        p_recordStoredResource(resource, manifest: manifest)
        return SparseCacheSnapshot(manifest)
    }

    @usableFromInline
    internal func p_insert(
        _ data: Data,
        in range: Range<Int>,
        resource: P_SparseCacheResource
    ) throws -> SparseCacheSnapshot
    {
        _ = try resource.loadIfNeeded(fileManager: p_storage.p_fileManager)
        let (descriptor, manifest) = try resource.descriptorAndManifest()
        guard manifest.expirationDate.map({ Date.now >= $0 }) != true else
        {
            throw SparseCacheError.entryExpired
        }
        guard range.upperBound <= manifest.capacity else
        {
            throw SparseCacheError.invalidRange
        }
        let missingRanges = SparseCacheSnapshot(manifest).missingRanges(
            in: range
        )
        guard !missingRanges.isEmpty else
        {
            p_recordAccess(to: resource.dataURL)
            return SparseCacheSnapshot(manifest)
        }
        do
        {
            for missingRange in missingRanges
            {
                let sourceLowerBound = missingRange.lowerBound
                    - range.lowerBound
                let sourceRange = Range(
                    uncheckedBounds: (
                        lower: sourceLowerBound,
                        upper: sourceLowerBound + missingRange.count
                    )
                )
                try Self.p_write(
                    data,
                    bytes: sourceRange,
                    to: descriptor,
                    at: missingRange.lowerBound
                )
            }
        }
        catch
        {
            resource.updateAccountedCapacity(
                to: p_capacity(of: resource),
                coordinator: p_storage.p_coordinator
            )
            p_recordStoredResource(resource, manifest: manifest)
            throw error
        }
        let (updated, _) = try resource.updateManifest {
            $0.insert(range)
        }
        let newCapacity = p_capacity(of: resource)
        resource.updateAccountedCapacity(
            to: newCapacity,
            coordinator: p_storage.p_coordinator
        )
        p_recordStoredResource(resource, manifest: updated)
        p_scheduleFlush(resource)
        return SparseCacheSnapshot(updated)
    }

    @usableFromInline
    internal func p_read(
        _ range: Range<Int>,
        resource: P_SparseCacheResource
    ) throws -> Data?
    {
        guard let manifest = try resource.loadIfNeeded(
            fileManager: p_storage.p_fileManager
        ), manifest.expirationDate.map({ Date.now >= $0 }) != true else
        {
            return nil
        }
        guard range.upperBound <= manifest.capacity,
              manifest.contains(range) else { return nil }
        let (descriptor, _) = try resource.descriptorAndManifest()
        let data = try Self.p_read(
            byteCount: range.count,
            from: descriptor,
            at: range.lowerBound
        )
        p_recordAccess(to: resource.dataURL)
        return data
    }

    @usableFromInline
    internal func p_remove(_ resource: P_SparseCacheResource) throws
    {
        resource.cancelFlushTask()
        let oldCapacity = p_capacity(of: resource)
        resource.invalidate()
        try p_removeFileIfPresent(resource.dataURL)
        try p_removeFileIfPresent(resource.manifestURL)
        p_storage.p_coordinator.updateTotalCapacity(
            from: oldCapacity,
            to: 0
        )
        p_storage.p_coordinator.forgetAccess(to: resource.dataURL)
    }

    @usableFromInline
    internal func p_removeAllFiles() throws
    {
        let oldCapacity = try DiskCacheStorage.p_indexedCapacity(
            in: p_directory,
            fileManager: p_storage.p_fileManager
        )
        p_storage.p_coordinator.sparseResources.invalidateResources(
            in: p_directory
        )
        if p_storage.p_fileManager.fileExists(atPath: p_directory.path)
        {
            try p_storage.p_fileManager.removeItem(at: p_directory)
        }
        try p_storage.p_fileManager.createDirectory(
            at: p_directory,
            withIntermediateDirectories: true
        )
        p_storage.p_coordinator.updateTotalCapacity(
            from: oldCapacity,
            to: 0
        )
        p_storage.p_coordinator.forgetDiskEntries(in: p_directory)
    }

    // MARK: - Manifest flushing

    @usableFromInline
    internal func p_scheduleFlush(_ resource: P_SparseCacheResource)
    {
        let delay = p_configuration.manifestFlushDelay
        // Debounced persistence intentionally outlives the triggering write.
        resource.scheduleFlush { [self, resource] in
            do
            {
                if delay > .zero { try await Task.sleep(for: delay) }
                try Task.checkCancellation()
                try await p_flush(resource)
            }
            catch {}
        }
    }

    @usableFromInline
    internal func p_flush(_ resource: P_SparseCacheResource) async throws
    {
        try await p_withExistingResourceAccess(
            resource,
            access: .metadataRead
        ) {
            try await self.p_storage.p_ioExecutor.run {
                try self.p_flushResource(resource)
            }
        }
    }

    @usableFromInline
    internal func p_flushResource(
        _ resource: P_SparseCacheResource
    ) throws
    {
        try resource.flushLock.withLock {
            guard let (manifest, revision) = resource.manifestForFlush() else { return }
            try p_writeManifest(manifest, to: resource.manifestURL)
            resource.markFlushed(revision)
            resource.updateAccountedCapacity(
                to: p_capacity(of: resource),
                coordinator: p_storage.p_coordinator
            )
            p_recordStoredResource(resource, manifest: manifest)
        }
    }

    @inlinable
    internal func p_recordStoredResource(
        _ resource: P_SparseCacheResource,
        manifest: P_SparseCacheManifest,
        at date: Date = .now
    )
    {
        p_storage.p_coordinator.recordStoredEntry(P_CacheDiskEntryRecord(
            primaryURL: resource.dataURL,
            relatedURLs: [resource.dataURL, resource.manifestURL],
            capacity: p_capacity(of: resource),
            lastAccessDate: date,
            expirationDate: manifest.expirationDate,
            isInvalid: false,
            isSparse: true
        ))
    }

    @usableFromInline
    internal func p_writeManifest(
        _ manifest: P_SparseCacheManifest,
        to url: URL
    ) throws
    {
        let data = try JSONEncoder().encode(manifest)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Access coordination

    @usableFromInline
    internal func p_withResourceAccess<Result>(
        for key: Key,
        access: P_CacheRangeGate.Access,
        _ operation: (P_SparseCacheResource) throws -> Result
    ) throws -> Result
    {
        let urls = try p_fileURLs(for: key)
        let coordinator = p_storage.p_coordinator
        coordinator.accessGate.acquire(.read)
        let namespaceGate = coordinator.fileGates.retainGate(for: p_directory)
        namespaceGate.acquire(.read)
        let resource = coordinator.sparseResources.retain(
            dataURL: urls.data,
            manifestURL: urls.manifest
        )
        let fileGate = coordinator.fileGates.retainGate(for: urls.data)
        fileGate.acquire(.read)
        let lease = resource.rangeGate.acquire(access)
        defer
        {
            resource.rangeGate.release(lease)
            fileGate.release(.read)
            coordinator.fileGates.releaseGate(fileGate, for: urls.data)
            coordinator.sparseResources.release(resource)
            namespaceGate.release(.read)
            coordinator.fileGates.releaseGate(namespaceGate, for: p_directory)
            coordinator.accessGate.release(.read)
            p_storage.p_requestAutomaticMaintenance()
        }
        return try operation(resource)
    }

    @usableFromInline
    internal func p_withResourceAccess<Result: Sendable>(
        for key: Key,
        access: P_CacheRangeGate.Access,
        _ operation: @escaping @Sendable (
            P_SparseCacheResource
        ) async throws -> Result
    ) async throws -> Result
    {
        let urls = try p_fileURLs(for: key)
        let coordinator = p_storage.p_coordinator
        try Task.checkCancellation()
        await coordinator.accessGate.acquire(.read)
        let namespaceGate = coordinator.fileGates.retainGate(for: p_directory)
        await namespaceGate.acquire(.read)
        let resource = coordinator.sparseResources.retain(
            dataURL: urls.data,
            manifestURL: urls.manifest
        )
        let fileGate = coordinator.fileGates.retainGate(for: urls.data)
        await fileGate.acquire(.read)
        let lease = await resource.rangeGate.acquire(access)
        do
        {
            try Task.checkCancellation()
            let result = try await operation(resource)
            resource.rangeGate.release(lease)
            fileGate.release(.read)
            coordinator.fileGates.releaseGate(fileGate, for: urls.data)
            coordinator.sparseResources.release(resource)
            namespaceGate.release(.read)
            coordinator.fileGates.releaseGate(namespaceGate, for: p_directory)
            coordinator.accessGate.release(.read)
            p_storage.p_requestAutomaticMaintenance()
            return result
        }
        catch
        {
            resource.rangeGate.release(lease)
            fileGate.release(.read)
            coordinator.fileGates.releaseGate(fileGate, for: urls.data)
            coordinator.sparseResources.release(resource)
            namespaceGate.release(.read)
            coordinator.fileGates.releaseGate(namespaceGate, for: p_directory)
            coordinator.accessGate.release(.read)
            p_storage.p_requestAutomaticMaintenance()
            throw error
        }
    }

    @usableFromInline
    internal func p_withExistingResourceAccess<Result: Sendable>(
        _ resource: P_SparseCacheResource,
        access: P_CacheRangeGate.Access,
        _ operation: @escaping @Sendable () async throws -> Result
    ) async throws -> Result
    {
        let coordinator = p_storage.p_coordinator
        try Task.checkCancellation()
        await coordinator.accessGate.acquire(.read)
        let namespaceGate = coordinator.fileGates.retainGate(for: p_directory)
        await namespaceGate.acquire(.read)
        let fileGate = coordinator.fileGates.retainGate(for: resource.dataURL)
        await fileGate.acquire(.read)
        let lease = await resource.rangeGate.acquire(access)
        do
        {
            try Task.checkCancellation()
            let result = try await operation()
            resource.rangeGate.release(lease)
            fileGate.release(.read)
            coordinator.fileGates.releaseGate(
                fileGate,
                for: resource.dataURL
            )
            namespaceGate.release(.read)
            coordinator.fileGates.releaseGate(namespaceGate, for: p_directory)
            coordinator.accessGate.release(.read)
            return result
        }
        catch
        {
            resource.rangeGate.release(lease)
            fileGate.release(.read)
            coordinator.fileGates.releaseGate(
                fileGate,
                for: resource.dataURL
            )
            namespaceGate.release(.read)
            coordinator.fileGates.releaseGate(namespaceGate, for: p_directory)
            coordinator.accessGate.release(.read)
            throw error
        }
    }

    // MARK: - File helpers

    @usableFromInline
    internal func p_fileURLs(for key: Key) throws
        -> (data: URL, manifest: URL)
    {
        let bytes = try p_keyEncoder.encode(key)
        let digest = SHA256.hash(data: bytes)
        let fileName = digest.reduce(into: "") { result, byte in
            result += String(format: "%02x", byte)
        }
        let base = p_directory.appending(
            component: fileName,
            directoryHint: .notDirectory
        )
        return (
            base.appendingPathExtension("sparsecache"),
            base.appendingPathExtension("sparsemeta")
        )
    }

    @usableFromInline
    internal func p_capacity(of resource: P_SparseCacheResource) -> UInt64
    {
        resource.p_currentCapacity()
    }

    @usableFromInline
    internal func p_recordAccess(to url: URL)
    {
        let now = Date.now
        guard p_storage.p_coordinator.recordAccess(
            at: url,
            date: now,
            minimumPersistenceInterval:
                p_storage.minimumAccessDateUpdateInterval
        ) else { return }

        var values = URLResourceValues()
        values.contentAccessDate = now
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }

    @usableFromInline
    internal func p_removeFileIfPresent(_ url: URL) throws
    {
        do { try p_storage.p_fileManager.removeItem(at: url) }
        catch CocoaError.fileNoSuchFile {}
    }

    @usableFromInline
    internal static func p_validatedRange(
        offset: Int,
        byteCount: Int
    ) throws -> Range<Int>
    {
        guard offset >= 0, byteCount > 0 else
        {
            throw SparseCacheError.invalidRange
        }
        let (upperBound, overflow) = offset.addingReportingOverflow(byteCount)
        guard !overflow else { throw SparseCacheError.invalidRange }
        return offset..<upperBound
    }

    @usableFromInline
    internal static func p_validate(_ range: Range<Int>) throws
    {
        guard range.lowerBound >= 0, !range.isEmpty else
        {
            throw SparseCacheError.invalidRange
        }
    }

    @usableFromInline
    internal static func p_write(
        _ data: Data,
        bytes sourceRange: Range<Int>,
        to descriptor: Int32,
        at offset: Int
    ) throws
    {
        precondition(
            sourceRange.lowerBound >= 0
                && sourceRange.upperBound <= data.count
                && !sourceRange.isEmpty,
            "Sparse cache source range is invalid"
        )
        var total = 0
        try data.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress else
            {
                throw SparseCacheError.invalidRange
            }
            while total < sourceRange.count
            {
                let count = Darwin.pwrite(
                    descriptor,
                    base.advanced(by: sourceRange.lowerBound + total),
                    sourceRange.count - total,
                    off_t(offset + total)
                )
                if count < 0
                {
                    if errno == EINTR { continue }
                    throw p_posixError()
                }
                guard count > 0 else
                {
                    throw SparseCacheError.incompleteWrite(
                        expectedByteCount: sourceRange.count,
                        actualByteCount: total
                    )
                }
                total += count
            }
        }
    }

    @usableFromInline
    internal static func p_read(
        byteCount: Int,
        from descriptor: Int32,
        at offset: Int
    ) throws -> Data
    {
        var result = Data(count: byteCount)
        var total = 0
        try result.withUnsafeMutableBytes { bytes in
            guard let base = bytes.baseAddress else { return }
            while total < byteCount
            {
                let count = Darwin.pread(
                    descriptor,
                    base.advanced(by: total),
                    byteCount - total,
                    off_t(offset + total)
                )
                if count < 0
                {
                    if errno == EINTR { continue }
                    throw p_posixError()
                }
                if count == 0 { break }
                total += count
            }
        }
        guard total == byteCount else
        {
            throw SparseCacheError.incompleteRead(
                expectedByteCount: byteCount,
                actualByteCount: total
            )
        }
        return result
    }

    @usableFromInline
    internal static func p_posixError() -> POSIXError
    {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension SparseCache where Key == String
{
    convenience init(
        storage: DiskCacheStorage,
        configuration: SparseCacheConfiguration = .init()
    ) throws
    {
        try self.init(
            storage: storage,
            configuration: configuration,
            keyEncoder: .utf8
        )
    }
}
