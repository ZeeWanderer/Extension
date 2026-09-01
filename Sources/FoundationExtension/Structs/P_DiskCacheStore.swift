//
//  P_DiskCacheStore.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

import CryptoKit
import Foundation

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
@usableFromInline
internal final class P_DiskCacheStore<
    Key: Hashable & Sendable,
    Value: Sendable
>: @unchecked Sendable
{
    @usableFromInline
    internal struct Metadata: Codable
    {
        @usableFromInline internal let version: Int
        @usableFromInline internal let storedAt: Date
        @usableFromInline internal let expirationDate: Date?
        @usableFromInline internal let cost: Int
        @usableFromInline internal let payloadSize: Int

        @inlinable
        internal init(
            version: Int,
            storedAt: Date,
            expirationDate: Date?,
            cost: Int,
            payloadSize: Int
        )
        {
            self.version = version
            self.storedAt = storedAt
            self.expirationDate = expirationDate
            self.cost = cost
            self.payloadSize = payloadSize
        }
    }

    @inlinable
    internal static var formatVersion: Int { 1 }

    @usableFromInline internal let storage: DiskCacheStorage
    @usableFromInline internal let keyEncoder: CacheKeyEncoder<Key>
    @usableFromInline internal let valueCoder: CacheValueCoder<Value>
    @usableFromInline internal let fileManager: FileManager
    @usableFromInline internal let directory: URL
    @usableFromInline internal let coordinator: P_CacheDiskDirectoryCoordinator
    @usableFromInline internal let ioExecutor: P_CacheIOExecutor

    @inlinable
    internal var ownership: P_CacheStoreOwnership { coordinator.ownership }

    @inlinable
    internal convenience init(
        configuration: DiskCacheConfiguration,
        keyEncoder: CacheKeyEncoder<Key>,
        valueCoder: CacheValueCoder<Value>
    ) throws
    {
        try self.init(
            storage: DiskCacheStorage(configuration: configuration),
            keyEncoder: keyEncoder,
            valueCoder: valueCoder
        )
    }

    @inlinable
    internal init(
        storage: DiskCacheStorage,
        keyEncoder: CacheKeyEncoder<Key>,
        valueCoder: CacheValueCoder<Value>
    ) throws
    {
        self.storage = storage
        self.keyEncoder = keyEncoder
        self.valueCoder = valueCoder
        self.fileManager = storage.p_fileManager
        self.directory = storage.directoryURL
        self.ioExecutor = storage.p_ioExecutor
        self.coordinator = storage.p_coordinator
        requestAutomaticMaintenance()
    }

    // MARK: - Store operations

    @inlinable
    internal func retrieve(for key: Key) throws -> CacheEntry<Value>?
    {
        coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        return try retrieveFile(at: url)
    }

    @inlinable
    internal func store(_ entry: CacheEntry<Value>, for key: Key) throws
    {
        coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        try storeFile(entry, at: url)
    }

    @inlinable
    internal func remove(for key: Key) throws
    {
        coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        try removeFile(at: url)
    }

    @inlinable
    internal func removeFile(at url: URL) throws
    {
        let oldCapacity = fileCapacity(at: url)
        do
        {
            try fileManager.removeItem(at: url)
            coordinator.updateTotalCapacity(from: oldCapacity, to: 0)
            coordinator.forgetAccess(to: url)
        }
        catch CocoaError.fileNoSuchFile
        {
            return
        }
    }

    @inlinable
    internal func removeAll() throws
    {
        coordinator.accessGate.acquire(.write)
        defer { coordinator.accessGate.release(.write) }

        try removeAllFiles()
    }

    // MARK: - Asynchronous store operations

    @inlinable
    internal func retrieveAsynchronously(
        for key: Key
    ) async throws -> CacheEntry<Value>?
    {
        await coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }
        try Task.checkCancellation()

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        await fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        try Task.checkCancellation()
        return try await ioExecutor.run {
            try self.retrieveFile(at: url)
        }
    }

    @inlinable
    internal func storeAsynchronously(
        _ entry: CacheEntry<Value>,
        for key: Key
    ) async throws
    {
        await coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }
        try Task.checkCancellation()

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        await fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        try Task.checkCancellation()
        try await ioExecutor.run {
            try self.storeFile(entry, at: url)
        }
    }

    @inlinable
    internal func removeAsynchronously(for key: Key) async throws
    {
        await coordinator.accessGate.acquire(.read)
        defer
        {
            coordinator.accessGate.release(.read)
            requestAutomaticMaintenance()
        }
        try Task.checkCancellation()

        let url = try fileURL(for: key)
        let fileGate = coordinator.fileGates.retainGate(for: url)
        await fileGate.acquire(.write)
        defer
        {
            fileGate.release(.write)
            coordinator.fileGates.releaseGate(fileGate, for: url)
        }
        try Task.checkCancellation()
        try await ioExecutor.run {
            try self.removeFile(at: url)
        }
    }

    @inlinable
    internal func removeAllAsynchronously() async throws
    {
        await coordinator.accessGate.acquire(.write)
        defer { coordinator.accessGate.release(.write) }
        try Task.checkCancellation()
        try await ioExecutor.run {
            try self.removeAllFiles()
        }
    }

    // MARK: - Unisolated file operations

    /// Called while this file's write gate and the directory access gate are
    /// held by either the synchronous or asynchronous operation.
    @inlinable
    internal func retrieveFile(at url: URL) throws -> CacheEntry<Value>?
    {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do
        {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let entry = try decodeEntry(data)
            guard !entry.isExpired() else
            {
                try? removeFile(at: url)
                return nil
            }
            recordAccess(to: url)
            return entry
        }
        catch CocoaError.fileReadNoSuchFile
        {
            return nil
        }
        catch
        {
            try? removeFile(at: url)
            throw error
        }
    }

    /// Called while this file's write gate and the directory access gate are
    /// held by either the synchronous or asynchronous operation.
    @inlinable
    internal func storeFile(
        _ entry: CacheEntry<Value>,
        at url: URL
    ) throws
    {
        let data = try encodeEntry(entry)
        let encodedCapacity = UInt64(data.count)
        if let maximumCapacity = storage.capacityPolicy.maximumCapacity,
           encodedCapacity > maximumCapacity
        {
            throw CacheError.diskEntryExceedsMaximumCapacity(
                encodedByteCount: encodedCapacity,
                maximumCapacity: maximumCapacity
            )
        }

        let oldCapacity = fileCapacity(at: url)
        try data.write(to: url, options: .atomic)
        let newCapacity = fileCapacity(at: url)
        coordinator.updateTotalCapacity(
            from: oldCapacity,
            to: newCapacity
        )
        let accessDate = Date.now
        coordinator.recordStoredEntry(P_CacheDiskEntryRecord(
            primaryURL: url,
            relatedURLs: [url],
            capacity: newCapacity,
            lastAccessDate: accessDate,
            expirationDate: entry.expirationDate,
            isInvalid: false,
            isSparse: false
        ))
    }

    /// Called while the directory write gate is held.
    @inlinable
    internal func removeAllFiles() throws
    {
        for url in try cacheFileURLs()
        {
            try removeFile(at: url)
        }
    }

    // MARK: - Maintenance and access accounting

    @inlinable
    internal func requestAutomaticMaintenance()
    {
        storage.p_requestAutomaticMaintenance()
    }

    @inlinable
    internal func recordAccess(to url: URL)
    {
        let now = Date.now
        guard coordinator.recordAccess(
            at: url,
            date: now,
            minimumPersistenceInterval:
                storage.minimumAccessDateUpdateInterval
        ) else { return }

        var values = URLResourceValues()
        values.contentAccessDate = now
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }

    @inlinable
    internal static func fileCapacity(
        from values: URLResourceValues
    ) -> UInt64
    {
        if let totalFileAllocatedSize = values.totalFileAllocatedSize
        {
            return UInt64(max(0, totalFileAllocatedSize))
        }
        if let fileAllocatedSize = values.fileAllocatedSize
        {
            return UInt64(max(0, fileAllocatedSize))
        }
        return UInt64(max(0, values.fileSize ?? 0))
    }

    // MARK: - Coding and file helpers

    @inlinable
    internal func fileURL(for key: Key) throws -> URL
    {
        let bytes = try keyEncoder.encode(key)
        let digest = SHA256.hash(data: bytes)
        let fileName = digest.reduce(into: "") { result, byte in
            result += String(format: "%02x", byte)
        }
        return directory
            .appending(component: fileName, directoryHint: .notDirectory)
            .appendingPathExtension("cache")
    }

    @inlinable
    internal func encodeEntry(_ entry: CacheEntry<Value>) throws -> Data
    {
        let payload = try valueCoder.encode(entry.value)
        let metadata = Metadata(
            version: Self.formatVersion,
            storedAt: entry.storedAt,
            expirationDate: entry.expirationDate,
            cost: entry.cost,
            payloadSize: payload.count
        )
        let metadataData = try JSONEncoder().encode(metadata)
        guard let metadataSize = UInt32(exactly: metadataData.count) else
        {
            throw CacheError.invalidDiskEntry
        }

        var result = Data(capacity: 4 + metadataData.count + payload.count)
        var bigEndianSize = metadataSize.bigEndian
        Swift.withUnsafeBytes(of: &bigEndianSize) { bytes in
            result.append(contentsOf: bytes)
        }
        result.append(metadataData)
        result.append(payload)
        return result
    }

    @inlinable
    internal func decodeEnvelope(
        _ data: Data
    ) throws -> (metadata: Metadata, payloadRange: Range<Int>)
    {
        guard data.count >= 4 else { throw CacheError.invalidDiskEntry }
        let metadataSize = data.prefix(4).reduce(UInt32(0)) { result, byte in
            (result << 8) | UInt32(byte)
        }
        let metadataEnd = 4 + Int(metadataSize)
        guard metadataEnd >= 4, metadataEnd <= data.count else
        {
            throw CacheError.invalidDiskEntry
        }

        let metadata = try JSONDecoder().decode(
            Metadata.self,
            from: data.subdata(in: 4..<metadataEnd)
        )
        guard metadata.version == Self.formatVersion,
              metadata.payloadSize == data.count - metadataEnd else
        {
            throw CacheError.invalidDiskEntry
        }
        return (metadata, metadataEnd..<data.count)
    }

    @inlinable
    internal func decodeEntry(_ data: Data) throws -> CacheEntry<Value>
    {
        let envelope = try decodeEnvelope(data)
        let value = try valueCoder.decode(data.subdata(in: envelope.payloadRange))
        return CacheEntry(
            value,
            storedAt: envelope.metadata.storedAt,
            expirationDate: envelope.metadata.expirationDate,
            cost: envelope.metadata.cost
        )
    }

    @inlinable
    internal func cacheFileURLs() throws -> [URL]
    {
        try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [
                .fileSizeKey,
                .fileAllocatedSizeKey,
                .totalFileAllocatedSizeKey,
                .contentAccessDateKey,
                .contentModificationDateKey,
            ],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "cache" }
    }

    @inlinable
    internal func fileCapacity(at url: URL) -> UInt64
    {
        let values = try? url.resourceValues(forKeys: [
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ])
        return values.map(Self.fileCapacity(from:)) ?? 0
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheStore
{
    /// Creates a persistent store in shared physical disk storage.
    ///
    /// Specialized caches created from the same ``DiskCacheStorage`` share its
    /// aggregate capacity and maintenance boundary.
    @inlinable
    static func disk(
        id: CacheStoreID = .disk,
        storage: DiskCacheStorage,
        keyEncoder: CacheKeyEncoder<Key>,
        valueCoder: CacheValueCoder<Value>
    ) throws -> Self
    {
        let store = try P_DiskCacheStore<Key, Value>(
            storage: storage,
            keyEncoder: keyEncoder,
            valueCoder: valueCoder
        )
        let synchronous = CacheStoreSynchronousOperations<Key, Value>(
            retrieve: { key in
                try store.retrieve(for: key)
            },
            store: { entry, key in
                try store.store(entry, for: key)
            },
            remove: { key in
                try store.remove(for: key)
            },
            removeAll: {
                try store.removeAll()
            },
            maintenance: { mode in
                try storage.performMaintenance(mode)
            }
        )
        return Self(
            id: id,
            retrieve: { key in
                try await store.retrieveAsynchronously(for: key)
            },
            store: { entry, key in
                try await store.storeAsynchronously(entry, for: key)
            },
            remove: { key in
                try await store.removeAsynchronously(for: key)
            },
            removeAll: {
                try await store.removeAllAsynchronously()
            },
            maintenance: { mode in
                try await storage.performMaintenance(mode)
            },
            synchronous: synchronous,
            ownership: store.ownership
        )
    }

    /// Creates a persistent file-backed store.
    ///
    /// Async operations isolate blocking Foundation file I/O on a dedicated
    /// utility executor instead of occupying Swift's cooperative executor.
    @inlinable
    static func disk(
        id: CacheStoreID = .disk,
        configuration: DiskCacheConfiguration = .init(),
        keyEncoder: CacheKeyEncoder<Key>,
        valueCoder: CacheValueCoder<Value>
    ) throws -> Self
    {
        let store = try P_DiskCacheStore<Key, Value>(
            configuration: configuration,
            keyEncoder: keyEncoder,
            valueCoder: valueCoder
        )
        let synchronous = CacheStoreSynchronousOperations<Key, Value>(
            retrieve: { key in
                try store.retrieve(for: key)
            },
            store: { entry, key in
                try store.store(entry, for: key)
            },
            remove: { key in
                try store.remove(for: key)
            },
            removeAll: {
                try store.removeAll()
            },
            maintenance: { mode in
                try store.storage.performMaintenance(mode)
            }
        )
        return Self(
            id: id,
            retrieve: { key in
                try await store.retrieveAsynchronously(for: key)
            },
            store: { entry, key in
                try await store.storeAsynchronously(entry, for: key)
            },
            remove: { key in
                try await store.removeAsynchronously(for: key)
            },
            removeAll: {
                try await store.removeAllAsynchronously()
            },
            maintenance: { mode in
                try await store.storage.performMaintenance(mode)
            },
            synchronous: synchronous,
            ownership: store.ownership
        )
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public extension CacheStore where Key == String, Value == Data
{
    /// Creates a String-keyed data store in shared physical disk storage.
    @inlinable
    static func disk(
        id: CacheStoreID = .disk,
        storage: DiskCacheStorage
    ) throws -> Self
    {
        try disk(
            id: id,
            storage: storage,
            keyEncoder: .utf8,
            valueCoder: .data
        )
    }

    /// Creates the common String-keyed, Data-valued disk store.
    @inlinable
    static func disk(
        id: CacheStoreID = .disk,
        configuration: DiskCacheConfiguration = .init()
    ) throws -> Self
    {
        try disk(
            id: id,
            configuration: configuration,
            keyEncoder: .utf8,
            valueCoder: .data
        )
    }
}
