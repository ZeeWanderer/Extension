//
//  CacheMaintenanceTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal final class P_CacheMaintenanceConcurrencyProbe: @unchecked Sendable
{
    internal let lock = NSLock()
    internal var activeCount = 0
    internal var maximumActiveCount = 0
    internal var modes: [CacheStoreID: CacheMaintenanceMode] = [:]

    internal func perform(
        storeID: CacheStoreID,
        mode: CacheMaintenanceMode
    ) async throws -> CacheStoreMaintenanceResult
    {
        lock.withLock {
            activeCount += 1
            maximumActiveCount = max(maximumActiveCount, activeCount)
            modes[storeID] = mode
        }
        defer {
            lock.withLock { activeCount -= 1 }
        }
        try await Task.sleep(for: .milliseconds(40))
        return CacheStoreMaintenanceResult(
            status: .completed,
            scannedEntryCount: 2,
            removedEntryCount: 1,
            capacityUnit: .bytes,
            removedCapacity: 10,
            remainingEntryCount: 1,
            remainingCapacity: 20
        )
    }

    internal func snapshot() -> (
        maximumActiveCount: Int,
        modes: [CacheStoreID: CacheMaintenanceMode]
    )
    {
        lock.withLock { (maximumActiveCount, modes) }
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal actor P_CacheMaintenanceGate
{
    internal var hasStarted = false
    internal var startWaiters: [CheckedContinuation<Void, Never>] = []
    internal var releaseContinuation: CheckedContinuation<Void, Never>?

    internal func perform() async -> CacheStoreMaintenanceResult
    {
        hasStarted = true
        let waiters = startWaiters
        startWaiters.removeAll()
        for waiter in waiters { waiter.resume() }

        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
        return CacheStoreMaintenanceResult(status: .completed)
    }

    internal func waitUntilStarted() async
    {
        guard !hasStarted else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    internal func release()
    {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
internal func p_makeMaintenanceStore(
    id: CacheStoreID,
    maintenance: (@Sendable (CacheMaintenanceMode) async throws -> CacheStoreMaintenanceResult)?,
    synchronousMaintenance: (@Sendable (CacheMaintenanceMode) throws -> CacheStoreMaintenanceResult)? = nil
) -> CacheStore<String, Int>
{
    let synchronous = CacheStoreSynchronousOperations<String, Int>(
        retrieve: { _ in nil },
        store: { _, _ in },
        remove: { _ in },
        removeAll: {},
        maintenance: synchronousMaintenance
    )
    return CacheStore(
        id: id,
        retrieve: { _ in nil },
        store: { _, _ in },
        remove: { _ in },
        removeAll: {},
        maintenance: maintenance,
        synchronous: synchronous
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheMaintenanceTests: XCTestCase
{
    func testSelectedStoresRunConcurrentlyAndReportsRetainSelectionOrder() async throws
    {
        let probe = P_CacheMaintenanceConcurrencyProbe()
        let first = p_makeMaintenanceStore(
            id: "first",
            maintenance: { mode in
                try await probe.perform(storeID: "first", mode: mode)
            }
        )
        let second = p_makeMaintenanceStore(
            id: "second",
            maintenance: { mode in
                try await probe.perform(storeID: "second", mode: mode)
            }
        )
        let ignored = p_makeMaintenanceStore(
            id: "ignored",
            maintenance: { _ in
                XCTFail("Unselected store was maintained")
                return .init(status: .completed)
            }
        )
        let cache = try Cache(stores: [first, second, ignored])

        let report = try await cache.performMaintenance(
            storeIDs: ["second", "first", "second"],
            mode: .forced
        )

        XCTAssertEqual(report.storeResults.map(\.storeID), ["second", "first"])
        XCTAssertTrue(report.failures.isEmpty)
        XCTAssertEqual(report[storeID: "first"]?.removedEntryCount, 1)
        XCTAssertEqual(report[storeID: "second"]?.remainingCapacity, 20)
        let snapshot = probe.snapshot()
        XCTAssertEqual(snapshot.maximumActiveCount, 2)
        XCTAssertEqual(snapshot.modes, [
            "first": .forced,
            "second": .forced,
        ])
    }

    func testUnsupportedStoresAreReportedWithoutFailure() async throws
    {
        let cache = Cache<String, Int>()
        let report = try await cache.performMaintenance()

        XCTAssertEqual(report.storeResults.map(\.storeID), [.memory])
        XCTAssertEqual(report[storeID: .memory]?.status, .unsupported)
        XCTAssertTrue(report.failures.isEmpty)
    }

    func testMaintenanceFailuresCanBeReportedOrThrown() async throws
    {
        let failing = p_makeMaintenanceStore(
            id: "failing",
            maintenance: { _ in
                throw P_CacheInjectedFailure(
                    storeID: "failing",
                    operation: .maintenance
                )
            }
        )
        let successful = p_makeMaintenanceStore(
            id: "successful",
            maintenance: { _ in .init(status: .completed) }
        )
        let cache = try Cache(stores: [failing, successful])

        let ignored = try await cache.performMaintenance(
            failurePolicy: .ignore
        )
        XCTAssertEqual(ignored.storeResults.map(\.storeID), ["successful"])
        XCTAssertEqual(ignored.failures.map(\.storeID), ["failing"])
        XCTAssertEqual(ignored.failures.map(\.operation), [.maintenance])

        do
        {
            _ = try await cache.performMaintenance()
            XCTFail("Expected maintenance to fail")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(failures.map(\.storeID), ["failing"])
            XCTAssertEqual(failures.map(\.operation), [.maintenance])
        }
    }

    func testStartMaintenanceReturnsAJobThatCanBeAwaitedLater() async throws
    {
        let gate = P_CacheMaintenanceGate()
        let store = p_makeMaintenanceStore(
            id: "gated",
            maintenance: { _ in await gate.perform() }
        )
        let cache = try Cache(stores: [store])

        let maintenance = cache.startMaintenance()
        await gate.waitUntilStarted()
        await gate.release()
        let report = try await maintenance.value

        XCTAssertEqual(report[storeID: "gated"]?.status, .completed)
    }

    func testCancellingAStartedMaintenanceJobPropagatesCancellation() async throws
    {
        let gate = P_CacheMaintenanceGate()
        let store = p_makeMaintenanceStore(
            id: "gated",
            maintenance: { _ in await gate.perform() }
        )
        let cache = try Cache(stores: [store])

        let maintenance = cache.startMaintenance()
        await gate.waitUntilStarted()
        maintenance.cancel()
        await gate.release()

        do
        {
            _ = try await maintenance.value
            XCTFail("Expected maintenance cancellation")
        }
        catch is CancellationError {}
        catch { XCTFail("Unexpected error: \(error)") }
    }

    func testUnknownMaintenanceStoreIsRejectedBeforeAnyStoreRuns() async throws
    {
        let probe = P_CacheMaintenanceConcurrencyProbe()
        let store = p_makeMaintenanceStore(
            id: "known",
            maintenance: { mode in
                try await probe.perform(storeID: "known", mode: mode)
            }
        )
        let cache = try Cache(stores: [store])

        do
        {
            _ = try await cache.performMaintenance(storeIDs: ["missing"])
            XCTFail("Expected an unknown store failure")
        }
        catch CacheError.unknownStoreID("missing") {}
        catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertTrue(probe.snapshot().modes.isEmpty)
    }

    func testSynchronousMaintenanceUsesTheBlockingStoreOperation() throws
    {
        let store = p_makeMaintenanceStore(
            id: "synchronous",
            maintenance: { _ in .init(status: .completed) },
            synchronousMaintenance: { mode in
                XCTAssertEqual(mode, .ifNeeded)
                return .init(
                    status: .completed,
                    scannedEntryCount: 4,
                    remainingEntryCount: 4
                )
            }
        )
        let cache = try Cache(stores: [store])

        let report = try cache.performMaintenance(mode: .ifNeeded)

        XCTAssertEqual(report[storeID: "synchronous"]?.scannedEntryCount, 4)
    }

    func testSynchronousMaintenanceRejectsAnAsyncOnlyImplementation() throws
    {
        let store = CacheStore<String, Int>(
            id: "async-only",
            retrieve: { _ in nil },
            store: { _, _ in },
            remove: { _ in },
            removeAll: {},
            maintenance: { _ in .init(status: .completed) }
        )
        let cache = try Cache(stores: [store])

        XCTAssertThrowsError(try cache.performMaintenance()) { error in
            guard case let CacheError.storeFailures(failures) = error,
                  failures.count == 1,
                  failures[0].storeID == "async-only",
                  failures[0].operation == .maintenance,
                  case CacheError.synchronousAccessUnavailable("async-only") =
                    failures[0].underlyingError
            else { return XCTFail("Unexpected error: \(error)") }
        }
    }

    func testSynchronousDiskMaintenanceEnforcesAllocatedCapacity() throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let capacityLimit: UInt64 = 3_000
        let configuration = DiskCacheConfiguration(
            name: "synchronous-maintenance",
            rootDirectory: root,
            capacityPolicy: .hard(
                maximumCapacity: capacityLimit,
                trimToCapacity: capacityLimit
            ),
            minimumMaintenanceInterval: 60 * 60,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for key in 0..<5
        {
            try cache.insert(
                Data(repeating: UInt8(key), count: 1_024),
                forKey: String(key)
            )
        }

        let report = try cache.performMaintenance()
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )

        XCTAssertEqual(report[storeID: .disk]?.status, .completed)
        XCTAssertLessThanOrEqual(
            try p_cacheAllocatedCapacity(in: directory),
            capacityLimit
        )
    }

    func testForcedDiskMaintenanceRemovesExpiredEntriesWithoutReadingThem() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "expired-maintenance",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 60 * 60,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache.insert(
            Data([1]),
            forKey: "expired",
            expirationDate: .distantPast
        )
        try await cache.insert(Data([2]), forKey: "live")

        let report = try await cache.performMaintenance()
        let expired = try await cache.value(forKey: "expired")
        let live = try await cache.value(forKey: "live")

        XCTAssertEqual(report[storeID: .disk]?.scannedEntryCount, 2)
        XCTAssertEqual(report[storeID: .disk]?.removedEntryCount, 1)
        XCTAssertNil(expired)
        XCTAssertEqual(live, Data([2]))
    }

    func testDiskMaintenanceCanPreserveExpiredEntriesWhenConfigured() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "preserved-expiration",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 0,
            maximumUnusedInterval: nil,
            removesExpiredEntries: false,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache.insert(
            Data([1]),
            forKey: "expired",
            expirationDate: .distantPast
        )

        let report = try await cache.performMaintenance()
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )

        XCTAssertEqual(report[storeID: .disk]?.removedEntryCount, 0)
        XCTAssertEqual(try p_cacheFiles(in: directory).count, 1)
    }

    func testUnusedDiskEntriesAreRemovedByAccessAge() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "access-age",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 60 * 60,
            maximumUnusedInterval: 60,
            performsAutomaticMaintenance: false
        )
        var cache: Cache<String, Data>? = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache?.insert(Data([1]), forKey: "old")
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        var oldFile = try XCTUnwrap(try p_cacheFiles(in: directory).first)
        try await cache?.insert(Data([2]), forKey: "new")
        var values = URLResourceValues()
        values.contentAccessDate = Date.now.addingTimeInterval(-120)
        values.contentModificationDate = Date.now.addingTimeInterval(-120)
        try oldFile.setResourceValues(values)

        // Simulate the next process launch. The live storage deliberately
        // keeps recent access dates in memory, so mutating its private files
        // out of band is not a valid way to age an entry during that lifetime.
        cache = nil
        let reopenedCache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])

        let report = try await reopenedCache.performMaintenance()
        let old = try await reopenedCache.value(forKey: "old")
        let new = try await reopenedCache.value(forKey: "new")

        XCTAssertEqual(report[storeID: .disk]?.removedEntryCount, 1)
        XCTAssertNil(old)
        XCTAssertEqual(new, Data([2]))
    }

    func testSizeMaintenanceRetainsARecentlyReadOlderEntry() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let payloadSize = 1024 * 1024
        let capacityLimit: UInt64 = 5 * 1024 * 1024 / 2
        let configuration = DiskCacheConfiguration(
            name: "lru-access",
            rootDirectory: root,
            capacityPolicy: .hard(
                maximumCapacity: capacityLimit,
                trimToCapacity: capacityLimit
            ),
            minimumMaintenanceInterval: 60 * 60,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for key in 0..<3
        {
            try await cache.insert(
                Data(repeating: UInt8(key), count: payloadSize),
                forKey: String(key)
            )
            try await Task.sleep(for: .milliseconds(2))
        }
        _ = try await cache.value(forKey: "0")

        _ = try await cache.performMaintenance()
        let recentlyRead = try await cache.value(forKey: "0")
        let leastRecentlyUsed = try await cache.value(forKey: "1")
        let newest = try await cache.value(forKey: "2")

        XCTAssertEqual(recentlyRead, Data(repeating: 0, count: payloadSize))
        XCTAssertNil(leastRecentlyUsed)
        XCTAssertEqual(newest, Data(repeating: 2, count: payloadSize))
    }

    func testIfNeededDiskMaintenanceIsThrottledAfterACompletedPass() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "throttle",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 60 * 60,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        try await cache.insert(Data([1]), forKey: "value")

        let forced = try await cache.performMaintenance(mode: .forced)
        let throttled = try await cache.performMaintenance(mode: .ifNeeded)

        XCTAssertEqual(forced[storeID: .disk]?.status, .completed)
        XCTAssertEqual(throttled[storeID: .disk]?.status, .skipped)
    }

    func testAutomaticDiskMaintenanceEventuallyEnforcesAllocatedCapacity() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let capacityLimit: UInt64 = 8_000
        let configuration = DiskCacheConfiguration(
            name: "automatic-capacity",
            rootDirectory: root,
            capacityPolicy: .hard(
                maximumCapacity: capacityLimit,
                trimToCapacity: capacityLimit
            ),
            minimumMaintenanceInterval: .greatestFiniteMagnitude,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: true
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])
        for key in 0..<30
        {
            try await cache.insert(
                Data(repeating: UInt8(key), count: 1_024),
                forKey: String(key)
            )
        }
        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )

        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        var capacity = try p_cacheAllocatedCapacity(in: directory)
        while capacity > capacityLimit, ContinuousClock.now < deadline
        {
            try await Task.sleep(for: .milliseconds(10))
            capacity = try p_cacheAllocatedCapacity(in: directory)
        }

        XCTAssertLessThanOrEqual(capacity, capacityLimit)
    }

    func testDiskMaintenanceAndWritesRemainSafeUnderContention() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "maintenance-contention",
            rootDirectory: root,
            capacityPolicy: .unlimited,
            minimumMaintenanceInterval: 0,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false,
            maximumConcurrentMaintenanceOperations: 4
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])

        try await withThrowingTaskGroup(of: Void.self) { group in
            for worker in 0..<24
            {
                group.addTask {
                    for revision in 0..<30
                    {
                        let value = Data([
                            UInt8(worker),
                            UInt8(revision),
                        ])
                        try await cache.insert(
                            value,
                            forKey: String(worker)
                        )
                    }
                }
            }
            group.addTask {
                for _ in 0..<30
                {
                    _ = try await cache.performMaintenance()
                    await Task.yield()
                }
            }
            try await group.waitForAll()
        }

        for worker in 0..<24
        {
            try await cache.insert(
                Data([UInt8(worker), 255]),
                forKey: String(worker)
            )
        }
        _ = try await cache.performMaintenance()
        for worker in 0..<24
        {
            let value = try await cache.value(forKey: String(worker))
            XCTAssertEqual(
                value,
                Data([UInt8(worker), 255])
            )
        }
    }

    func testDiskSoftCapacityProtectsRecentEntriesUntilAnAggressivePass() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let name = "soft-capacity"
        var cache: Cache<String, Data>? = try Cache(stores: [
            CacheStore<String, Data>.disk(
                configuration: .init(
                    name: name,
                    rootDirectory: root,
                    capacityPolicy: .unlimited,
                    maximumUnusedInterval: nil,
                    performsAutomaticMaintenance: false
                )
            ),
        ])
        for key in 0..<3
        {
            try await cache?.insert(
                Data(repeating: UInt8(key), count: 1_024),
                forKey: String(key)
            )
        }
        let directory = root.appending(
            component: name,
            directoryHint: .isDirectory
        )
        let initialCapacity = try p_cacheAllocatedCapacity(in: directory)
        XCTAssertGreaterThan(initialCapacity, 0)
        cache = nil

        let policy = CacheCapacityPolicy.soft(
            preferredCapacity: initialCapacity - 1,
            trimToCapacity: 0,
            maximumCapacity: initialCapacity * 2,
            recentAccessProtectionInterval: 60 * 60
        )
        cache = try Cache(stores: [
            CacheStore<String, Data>.disk(
                configuration: .init(
                    name: name,
                    rootDirectory: root,
                    capacityPolicy: policy,
                    maximumUnusedInterval: nil,
                    performsAutomaticMaintenance: false
                )
            ),
        ])

        let protectedReport = try await cache?.performMaintenance(
            mode: .forced
        )
        let protectedResult = try XCTUnwrap(
            protectedReport?[storeID: .disk]
        )
        XCTAssertEqual(protectedResult.capacityUnit, .bytes)
        XCTAssertEqual(protectedResult.removedEntryCount, 0)
        XCTAssertEqual(protectedResult.protectedEntryCount, 3)
        XCTAssertEqual(
            protectedResult.protectedCapacity,
            initialCapacity
        )
        XCTAssertEqual(
            protectedResult.remainingCapacity,
            initialCapacity
        )
        XCTAssertEqual(try p_cacheFiles(in: directory).count, 3)

        let aggressiveReport = try await cache?.performMaintenance(
            mode: .aggressive
        )
        let aggressiveResult = try XCTUnwrap(
            aggressiveReport?[storeID: .disk]
        )
        XCTAssertEqual(aggressiveResult.removedEntryCount, 3)
        XCTAssertEqual(aggressiveResult.remainingCapacity, 0)
        XCTAssertTrue(try p_cacheFiles(in: directory).isEmpty)
    }

    func testDiskHardCeilingOverridesRecentAccessProtection() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let name = "hard-capacity"
        var cache: Cache<String, Data>? = try Cache(stores: [
            CacheStore<String, Data>.disk(
                configuration: .init(
                    name: name,
                    rootDirectory: root,
                    capacityPolicy: .unlimited,
                    maximumUnusedInterval: nil,
                    performsAutomaticMaintenance: false
                )
            ),
        ])
        for key in 0..<3
        {
            try await cache?.insert(
                Data(repeating: UInt8(key), count: 1_024),
                forKey: String(key)
            )
        }
        let directory = root.appending(
            component: name,
            directoryHint: .isDirectory
        )
        let initialCapacity = try p_cacheAllocatedCapacity(in: directory)
        XCTAssertGreaterThan(initialCapacity, 1)
        cache = nil

        cache = try Cache(stores: [
            CacheStore<String, Data>.disk(
                configuration: .init(
                    name: name,
                    rootDirectory: root,
                    capacityPolicy: .soft(
                        preferredCapacity: initialCapacity / 2,
                        trimToCapacity: 0,
                        maximumCapacity: initialCapacity - 1,
                        recentAccessProtectionInterval: 60 * 60
                    ),
                    maximumUnusedInterval: nil,
                    performsAutomaticMaintenance: false
                )
            ),
        ])

        let report = try await cache?.performMaintenance(mode: .forced)
        let result = try XCTUnwrap(report?[storeID: .disk])

        XCTAssertTrue(result.didExceedMaximumCapacity)
        XCTAssertEqual(result.protectedEntryCount, 0)
        XCTAssertEqual(result.removedEntryCount, 3)
        XCTAssertEqual(result.remainingCapacity, 0)
    }

    func testDiskRejectsAnEntryLargerThanItsHardCeiling() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        let configuration = DiskCacheConfiguration(
            name: "oversized-entry",
            rootDirectory: root,
            capacityPolicy: .hard(maximumCapacity: 128),
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try Cache(stores: [
            CacheStore<String, Data>.disk(configuration: configuration),
        ])

        do
        {
            try await cache.insert(
                Data(repeating: 1, count: 1_024),
                forKey: "oversized"
            )
            XCTFail("Expected the oversized entry to be rejected")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            guard failures.count == 1,
                  case let CacheError.diskEntryExceedsMaximumCapacity(
                    encodedByteCount,
                    maximumCapacity
                  ) = failures[0].underlyingError
            else { return XCTFail("Unexpected error: \(error)") }
            XCTAssertGreaterThan(encodedByteCount, maximumCapacity)
            XCTAssertEqual(maximumCapacity, 128)
        }

        let directory = root.appending(
            component: configuration.name,
            directoryHint: .isDirectory
        )
        XCTAssertTrue(try p_cacheFiles(in: directory).isEmpty)
    }
}
