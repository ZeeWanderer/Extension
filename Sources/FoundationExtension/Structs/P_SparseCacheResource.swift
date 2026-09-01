//
//  P_SparseCacheResource.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Darwin
import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_SparseCacheResource: @unchecked Sendable
{
    @usableFromInline internal let dataURL: URL
    @usableFromInline internal let manifestURL: URL
    @usableFromInline internal let rangeGate = P_CacheRangeGate()
    @usableFromInline internal let stateLock = NSLock()
    @usableFromInline internal let flushLock = NSLock()
    @usableFromInline internal var isLoaded = false
    @usableFromInline internal var manifest: P_SparseCacheManifest?
    @usableFromInline internal var fileDescriptor: Int32 = -1
    @usableFromInline internal var revision: UInt64 = 0
    @usableFromInline internal var flushedRevision: UInt64 = 0
    @usableFromInline internal var accountedCapacity: UInt64 = 0
    @usableFromInline internal var flushTask: Task<Void, Never>?

    @inlinable
    internal init(dataURL: URL, manifestURL: URL)
    {
        self.dataURL = dataURL
        self.manifestURL = manifestURL
    }

    deinit
    {
        flushTask?.cancel()
        if fileDescriptor >= 0 { Darwin.close(fileDescriptor) }
    }

    @usableFromInline
    internal func loadIfNeeded(fileManager: FileManager) throws
        -> P_SparseCacheManifest?
    {
        try stateLock.withLock {
            if isLoaded { return manifest }
            guard fileManager.fileExists(atPath: dataURL.path),
                  fileManager.fileExists(atPath: manifestURL.path) else
            {
                p_invalidateLocked()
                isLoaded = true
                return nil
            }

            let data = try Data(contentsOf: manifestURL)
            let decoded: P_SparseCacheManifest
            do
            {
                decoded = try JSONDecoder().decode(
                    P_SparseCacheManifest.self,
                    from: data
                )
            }
            catch
            {
                throw SparseCacheError.invalidEntry
            }
            guard decoded.isValid,
                  (try? dataURL.resourceValues(forKeys: [.fileSizeKey]))?
                    .fileSize == decoded.capacity else
            {
                throw SparseCacheError.invalidEntry
            }

            let descriptor = Darwin.open(dataURL.path, O_RDWR | O_CLOEXEC)
            guard descriptor >= 0 else
            {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            fileDescriptor = descriptor
            manifest = decoded
            isLoaded = true
            revision = 0
            flushedRevision = 0
            accountedCapacity = p_currentCapacity()
            return decoded
        }
    }

    @usableFromInline
    internal func replace(
        manifest: P_SparseCacheManifest,
        fileDescriptor: Int32,
        accountedCapacity: UInt64
    )
    {
        stateLock.withLock {
            p_invalidateLocked()
            self.manifest = manifest
            self.fileDescriptor = fileDescriptor
            self.isLoaded = true
            self.revision = 0
            self.flushedRevision = 0
            self.accountedCapacity = accountedCapacity
        }
    }

    @usableFromInline
    internal func snapshot() -> P_SparseCacheManifest?
    {
        stateLock.withLock { manifest }
    }

    @usableFromInline
    internal func updateManifest(
        _ update: (inout P_SparseCacheManifest) -> Void
    ) throws -> (P_SparseCacheManifest, UInt64)
    {
        try stateLock.withLock {
            guard var manifest else
            {
                throw SparseCacheError.entryNotPrepared
            }
            update(&manifest)
            self.manifest = manifest
            revision &+= 1
            return (manifest, revision)
        }
    }

    @usableFromInline
    internal func descriptorAndManifest() throws
        -> (Int32, P_SparseCacheManifest)
    {
        try stateLock.withLock {
            guard fileDescriptor >= 0, let manifest else
            {
                throw SparseCacheError.entryNotPrepared
            }
            return (fileDescriptor, manifest)
        }
    }

    @usableFromInline
    internal func manifestForFlush()
        -> (P_SparseCacheManifest, UInt64)?
    {
        stateLock.withLock {
            guard revision > flushedRevision, let manifest else { return nil }
            return (manifest, revision)
        }
    }

    @usableFromInline
    internal func markFlushed(_ revision: UInt64)
    {
        stateLock.withLock {
            flushedRevision = max(flushedRevision, revision)
            if flushedRevision >= self.revision { flushTask = nil }
        }
    }

    @usableFromInline
    internal func replaceFlushTask(_ task: Task<Void, Never>)
    {
        stateLock.withLock {
            flushTask?.cancel()
            flushTask = task
        }
    }

    @usableFromInline
    internal func cancelFlushTask()
    {
        stateLock.withLock {
            flushTask?.cancel()
            flushTask = nil
        }
    }

    @usableFromInline
    internal func updateAccountedCapacity(
        to newCapacity: UInt64,
        coordinator: P_CacheDiskDirectoryCoordinator
    )
    {
        let oldCapacity = stateLock.withLock { () -> UInt64 in
            let oldCapacity = accountedCapacity
            accountedCapacity = newCapacity
            return oldCapacity
        }
        coordinator.updateTotalCapacity(
            from: oldCapacity,
            to: newCapacity
        )
    }

    @usableFromInline
    internal var currentAccountedCapacity: UInt64
    {
        stateLock.withLock { accountedCapacity }
    }

    @usableFromInline
    internal func invalidate()
    {
        stateLock.withLock { p_invalidateLocked() }
    }

    @usableFromInline
    internal func p_invalidateLocked()
    {
        flushTask?.cancel()
        flushTask = nil
        if fileDescriptor >= 0 { Darwin.close(fileDescriptor) }
        fileDescriptor = -1
        manifest = nil
        isLoaded = false
        revision = 0
        flushedRevision = 0
        accountedCapacity = 0
    }

    @usableFromInline
    internal func p_currentCapacity() -> UInt64
    {
        P_DiskCacheStorageMaintenance.saturatingSum(
            P_DiskCacheStorageMaintenance.fileCapacity(
                from: (try? dataURL.resourceValues(forKeys: [
                    .fileSizeKey,
                    .fileAllocatedSizeKey,
                    .totalFileAllocatedSizeKey,
                ])) ?? URLResourceValues()
            ),
            P_DiskCacheStorageMaintenance.fileCapacity(
                from: (try? manifestURL.resourceValues(forKeys: [
                    .fileSizeKey,
                    .fileAllocatedSizeKey,
                    .totalFileAllocatedSizeKey,
                ])) ?? URLResourceValues()
            )
        )
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_SparseCacheResourceRegistry: @unchecked Sendable
{
    @usableFromInline
    internal struct Record
    {
        @usableFromInline internal let resource: P_SparseCacheResource
        @usableFromInline internal var users: Int

        @inlinable
        internal init(resource: P_SparseCacheResource, users: Int)
        {
            self.resource = resource
            self.users = users
        }
    }

    @usableFromInline internal let lock = NSLock()
    @usableFromInline internal let maximumRetainedResourceCount: Int
    @usableFromInline internal var records: [String: Record] = [:]

    @inlinable
    internal init(maximumRetainedResourceCount: Int)
    {
        self.maximumRetainedResourceCount = max(
            0,
            maximumRetainedResourceCount
        )
    }

    @inlinable
    internal func retain(
        dataURL: URL,
        manifestURL: URL
    ) -> P_SparseCacheResource
    {
        let key = p_key(for: dataURL)
        return lock.withLock {
            if var record = records[key]
            {
                record.users += 1
                records[key] = record
                return record.resource
            }
            let resource = P_SparseCacheResource(
                dataURL: dataURL,
                manifestURL: manifestURL
            )
            records[key] = Record(resource: resource, users: 1)
            return resource
        }
    }

    @inlinable
    internal func release(_ resource: P_SparseCacheResource)
    {
        let key = p_key(for: resource.dataURL)
        lock.withLock {
            guard var record = records[key] else { return }
            precondition(
                record.resource === resource,
                "Mismatched sparse cache resource"
            )
            record.users -= 1
            if record.users == 0,
               records.count > maximumRetainedResourceCount,
               resource.manifestForFlush() == nil
            {
                records[key] = nil
            }
            else
            {
                records[key] = record
            }
        }
    }

    @inlinable
    internal func invalidate(_ dataURL: URL)
    {
        let resource = lock.withLock {
            records[p_key(for: dataURL)]?.resource
        }
        resource?.invalidate()
    }

    @inlinable
    internal func invalidateAll()
    {
        let resources = lock.withLock { records.values.map(\.resource) }
        for resource in resources { resource.invalidate() }
    }

    @inlinable
    internal func invalidateResources(in directory: URL)
    {
        let prefix = p_key(for: directory) + "/"
        let resources = lock.withLock {
            records.compactMap { key, record in
                key.hasPrefix(prefix) ? record.resource : nil
            }
        }
        for resource in resources { resource.invalidate() }
    }

    @inlinable
    internal func p_key(for url: URL) -> String
    {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }
}
