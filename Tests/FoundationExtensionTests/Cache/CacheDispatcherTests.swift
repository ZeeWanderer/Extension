//
//  CacheDispatcherTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation
import XCTest
import FoundationExtension

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private actor CacheAccessProbe
{
    private var entry: CacheEntry<Int>?
    private var events: [String] = []
    private var readsAreBlocked = true
    private var readWaiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int)
    {
        self.entry = CacheEntry(value)
    }

    func retrieve(for key: String) async -> CacheEntry<Int>?
    {
        events.append("read-start-\(key)")
        if readsAreBlocked
        {
            await withCheckedContinuation { continuation in
                readWaiters.append(continuation)
            }
        }
        events.append("read-end-\(key)")
        return entry
    }

    func store(_ entry: CacheEntry<Int>, for key: String)
    {
        events.append("write-start-\(key)")
        self.entry = entry
        events.append("write-end-\(key)")
    }

    func remove(for key: String)
    {
        events.append("remove-\(key)")
        entry = nil
    }

    func removeAll()
    {
        events.append("remove-all")
        entry = nil
    }

    func releaseReads()
    {
        readsAreBlocked = false
        let waiters = readWaiters
        readWaiters.removeAll()
        for waiter in waiters
        {
            waiter.resume()
        }
    }

    func eventSnapshot() -> [String]
    {
        events
    }

    func waitForEventCount(
        matching prefix: String,
        _ count: Int
    ) async throws
    {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while events.lazy.filter({ $0.hasPrefix(prefix) }).count < count
        {
            guard clock.now < deadline else
            {
                throw CacheProbeError.timedOut(prefix)
            }
            await Task.yield()
        }
    }
}

private enum CacheProbeError: Error
{
    case timedOut(String)
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private actor CacheOperationSignal
{
    private var hasSignalled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func signal()
    {
        hasSignalled = true
        let waiters = waiters
        self.waiters.removeAll()
        for waiter in waiters
        {
            waiter.resume()
        }
    }

    func wait() async
    {
        guard !hasSignalled else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private final class CacheTaskExecutorProbe: @unchecked Sendable
{
    private let lock = NSLock()
    private var observationCount = 0
    private var nonpreferredExecutorCount = 0

    func recordCurrentExecutor()
    {
        let usesPreferredExecutor = withUnsafeCurrentTask { task in
            guard let currentExecutor = task?.unownedTaskExecutor else
            {
                return false
            }
            return currentExecutor
                != globalConcurrentExecutor.asUnownedTaskExecutor()
        }

        lock.lock()
        observationCount += 1
        if !usesPreferredExecutor
        {
            nonpreferredExecutorCount += 1
        }
        lock.unlock()
    }

    func snapshot() -> (observationCount: Int, nonpreferredExecutorCount: Int)
    {
        lock.lock()
        defer { lock.unlock() }
        return (observationCount, nonpreferredExecutorCount)
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeProbeStore(
    _ probe: CacheAccessProbe,
    id: CacheStoreID = "probe"
) -> CacheStore<String, Int>
{
    CacheStore(
        id: id,
        retrieve: { key in
            await probe.retrieve(for: key)
        },
        store: { entry, key in
            await probe.store(entry, for: key)
        },
        remove: { key in
            await probe.remove(for: key)
        },
        removeAll: {
            await probe.removeAll()
        }
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func insertSynchronously(
    _ value: Int,
    into cache: Cache<String, Int>,
    forKey key: String
) throws
{
    try cache.insert(value, forKey: key)
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func valueSynchronously(
    in cache: Cache<String, Int>,
    forKey key: String
) throws -> Int?
{
    try cache.value(forKey: key)
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheDispatcherTests: XCTestCase
{
    func testStoresInAReadStageRunConcurrentlyWithStablePriority() async throws
    {
        let firstProbe = CacheAccessProbe(value: 1)
        let secondProbe = CacheAccessProbe(value: 2)
        let cache = try Cache(stores: [
            makeProbeStore(firstProbe, id: "first"),
            makeProbeStore(secondProbe, id: "second"),
        ])
        let route = CacheRoute(readStages: [["first", "second"]])

        let lookup = Task {
            try await cache.value(forKey: "value", route: route)
        }

        try await firstProbe.waitForEventCount(
            matching: "read-start-value",
            1
        )
        try await secondProbe.waitForEventCount(
            matching: "read-start-value",
            1
        )
        await secondProbe.releaseReads()
        await firstProbe.releaseReads()

        let value = try await lookup.value
        XCTAssertEqual(value, 1)
    }

    func testDefaultHierarchyPromotesOnlyToConfiguredStores() async throws
    {
        let memory0 = CacheStore<String, Int>.memory(id: "memory0")
        let memory1 = CacheStore<String, Int>.memory(id: "memory1")
        let source = CacheStore<String, Int>.memory(id: "source")
        let cache = try Cache(stores: [memory0, memory1, source])

        let sourceOnly = CacheRoute(
            readStages: [["source"]],
            writeStores: ["source"]
        )
        try await cache.insert(42, forKey: "value", route: sourceOnly)

        let promoteToMemory0 = CacheRoute(
            readStages: [["source"]],
            writeStores: ["source"],
            promotions: ["source": ["memory0"]]
        )
        let promoted = try await cache.value(
            forKey: "value",
            route: promoteToMemory0
        )
        XCTAssertEqual(promoted, 42)

        let memory0Value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory0"]])
        )
        XCTAssertEqual(memory0Value, 42)
        let memory1Value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory1"]])
        )
        XCTAssertNil(memory1Value)
    }

    func testSelectiveWriteInvalidatesStoresOutsideTheRoute() async throws
    {
        let memory0 = CacheStore<String, Int>.memory(id: "memory0")
        let memory1 = CacheStore<String, Int>.memory(id: "memory1")
        let cache = try Cache(stores: [memory0, memory1])

        try await cache.insert(1, forKey: "value")
        try await cache.insert(
            2,
            forKey: "value",
            route: CacheRoute(writeStores: ["memory1"])
        )

        let memory0Value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory0"]])
        )
        let memory1Value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory1"]])
        )
        XCTAssertNil(memory0Value)
        XCTAssertEqual(memory1Value, 2)
    }

    func testFailedWriteRollsBackEveryStore() async throws
    {
        let memory = CacheStore<String, Int>.memory(id: "memory")
        let failing = CacheStore<String, Int>(
            id: "failing",
            retrieve: { _ in nil },
            store: { _, _ in throw CacheProbeError.timedOut("store") },
            remove: { _ in },
            removeAll: {}
        )
        let cache = try Cache(stores: [memory, failing])

        do
        {
            try await cache.insert(1, forKey: "value")
            XCTFail("The failing store should make the atomic write fail")
        }
        catch let CacheError.storeFailures(failures)
        {
            XCTAssertEqual(failures.first?.storeID, "failing")
        }

        let value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory"]])
        )
        XCTAssertNil(value)
    }

    func testFailedPromotionRollsBackEveryPromotionTarget() async throws
    {
        let promoted = CacheStore<String, Int>.memory(id: "promoted")
        let failing = CacheStore<String, Int>(
            id: "failing",
            retrieve: { _ in nil },
            store: { _, _ in throw CacheProbeError.timedOut("promotion") },
            remove: { _ in },
            removeAll: {}
        )
        let source = CacheStore<String, Int>.memory(id: "source")
        let cache = try Cache(stores: [promoted, failing, source])
        try await cache.insert(
            1,
            forKey: "value",
            route: CacheRoute(writeStores: ["source"])
        )

        let value = try await cache.value(
            forKey: "value",
            route: CacheRoute(
                readStages: [["source"]],
                promotions: ["source": ["promoted", "failing"]]
            )
        )
        XCTAssertEqual(value, 1)

        let promotedValue = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["promoted"]])
        )
        XCTAssertNil(promotedValue)
    }

    func testRouteProviderCanSelectDifferentStoreSets() async throws
    {
        let memory0 = CacheStore<String, Int>.memory(id: "memory0")
        let memory1 = CacheStore<String, Int>.memory(id: "memory1")
        let cache = try Cache(
            stores: [memory0, memory1],
            routeProvider: { key in
                let store: CacheStoreID = key.hasPrefix("hot-")
                    ? "memory0"
                    : "memory1"
                return CacheRoute(
                    readStages: [[store]],
                    writeStores: [store]
                )
            }
        )

        try await cache.insert(1, forKey: "hot-value")
        try await cache.insert(2, forKey: "cold-value")

        let hotValue = try await cache.value(forKey: "hot-value")
        let coldValue = try await cache.value(forKey: "cold-value")
        let hotValueInMemory1 = try await cache.value(
            forKey: "hot-value",
            route: CacheRoute(readStages: [["memory1"]])
        )
        let coldValueInMemory0 = try await cache.value(
            forKey: "cold-value",
            route: CacheRoute(readStages: [["memory0"]])
        )
        XCTAssertEqual(hotValue, 1)
        XCTAssertEqual(coldValue, 2)
        XCTAssertNil(hotValueInMemory1)
        XCTAssertNil(coldValueInMemory0)
    }

    func testFixedRouteAppliesWithoutAnOperationOverride() async throws
    {
        let memory0 = CacheStore<String, Int>.memory(id: "memory0")
        let memory1 = CacheStore<String, Int>.memory(id: "memory1")
        let cache = try Cache(
            stores: [memory0, memory1],
            route: CacheRoute(
                readStages: [["memory1"]],
                writeStores: ["memory1"]
            )
        )

        try await cache.insert(3, forKey: "value")

        let defaultValue = try await cache.value(forKey: "value")
        let memory0Value = try await cache.value(
            forKey: "value",
            route: CacheRoute(readStages: [["memory0"]])
        )
        XCTAssertEqual(defaultValue, 3)
        XCTAssertNil(memory0Value)
    }

    func testReadOnlyOperationsForTheSameKeyCanOverlap() async throws
    {
        let probe = CacheAccessProbe(value: 7)
        let cache = try Cache(stores: [makeProbeStore(probe)])

        async let first = cache.value(forKey: "same")
        async let second = cache.value(forKey: "same")

        try await probe.waitForEventCount(matching: "read-start-same", 2)
        await probe.releaseReads()

        let values = try await [first, second]
        XCTAssertEqual(values.compactMap { $0 }, [7, 7])
    }

    func testWriteIsAPerKeyBarrierAndQueuedWriterPrecedesLaterReaders() async throws
    {
        let probe = CacheAccessProbe(value: 1)
        let cache = try Cache(stores: [makeProbeStore(probe)])

        let firstRead = Task {
            try await cache.value(forKey: "same")
        }
        try await probe.waitForEventCount(matching: "read-start-same", 1)

        let write = Task {
            try await cache.insert(2, forKey: "same")
        }
        try await Task.sleep(for: .milliseconds(20))

        let secondRead = Task {
            try await cache.value(forKey: "same")
        }
        try await Task.sleep(for: .milliseconds(20))

        var events = await probe.eventSnapshot()
        XCTAssertEqual(events.filter { $0 == "read-start-same" }.count, 1)
        XCTAssertFalse(events.contains("write-start-same"))

        await probe.releaseReads()

        let firstValue = try await firstRead.value
        XCTAssertEqual(firstValue, 1)
        try await write.value
        let secondValue = try await secondRead.value
        XCTAssertEqual(secondValue, 2)

        events = await probe.eventSnapshot()
        XCTAssertEqual(events, [
            "read-start-same",
            "read-end-same",
            "write-start-same",
            "write-end-same",
            "read-start-same",
            "read-end-same",
        ])
    }

    func testDifferentKeysDoNotShareAnIsolationBoundary() async throws
    {
        let probe = CacheAccessProbe(value: 9)
        let cache = try Cache(stores: [makeProbeStore(probe)])

        async let first = cache.value(forKey: "first")
        async let second = cache.value(forKey: "second")

        try await probe.waitForEventCount(matching: "read-start-", 2)
        await probe.releaseReads()

        let values = try await [first, second]
        XCTAssertEqual(values.compactMap { $0 }, [9, 9])
    }

    func testRemoveAllWaitsForActiveKeyOperations() async throws
    {
        let probe = CacheAccessProbe(value: 9)
        let cache = try Cache(stores: [makeProbeStore(probe)])
        let removalStarted = CacheOperationSignal()

        let read = Task {
            try await cache.value(forKey: "value")
        }
        try await probe.waitForEventCount(matching: "read-start-value", 1)

        let removal = Task {
            await removalStarted.signal()
            try await cache.removeAll()
        }
        await removalStarted.wait()
        try await Task.sleep(for: .milliseconds(20))
        let eventsWhileReading = await probe.eventSnapshot()
        XCTAssertFalse(eventsWhileReading.contains("remove-all"))

        await probe.releaseReads()
        let readValue = try await read.value
        try await removal.value
        let finalEvents = await probe.eventSnapshot()
        XCTAssertEqual(readValue, 9)
        XCTAssertEqual(finalEvents, [
            "read-start-value",
            "read-end-value",
            "remove-all",
        ])
    }

    func testSynchronousAndAsynchronousOperationsShareStorage() async throws
    {
        let cache = Cache<String, Int>()

        try insertSynchronously(3, into: cache, forKey: "value")
        let asyncValue = try await cache.value(forKey: "value")
        XCTAssertEqual(asyncValue, 3)

        try await cache.insert(4, forKey: "value")
        XCTAssertEqual(
            try valueSynchronously(in: cache, forKey: "value"),
            4
        )
    }

    func testAsyncOnlyStoreRejectsSynchronousAccess() throws
    {
        let store = CacheStore<String, Int>(
            id: "async",
            retrieve: { _ in nil },
            store: { _, _ in },
            remove: { _ in },
            removeAll: {}
        )
        let cache = try Cache(stores: [store])

        XCTAssertThrowsError(
            try valueSynchronously(in: cache, forKey: "value")
        ) { error in
            guard case let CacheError.synchronousAccessUnavailable(storeID) = error else
            {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(storeID, "async")
        }
    }

    func testUnknownRouteStoreFailsBeforeAccess() async throws
    {
        let cache = Cache<String, Int>()

        do
        {
            _ = try await cache.value(
                forKey: "value",
                route: CacheRoute(readStages: [["missing"]])
            )
            XCTFail("An unknown store should fail route compilation")
        }
        catch let CacheError.unknownStoreID(storeID)
        {
            XCTAssertEqual(storeID, "missing")
        }
    }

    func testDiskStorePersistsValuesAndDoesNotCollapseSanitizedKeys() async throws
    {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let configuration = DiskCacheConfiguration(
            name: "disk-test",
            rootDirectory: rootDirectory,
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil
        )
        let firstStore = try CacheStore<String, Data>.disk(
            id: "disk",
            configuration: configuration
        )
        var cache: Cache<String, Data>? = try Cache(stores: [firstStore])

        try await cache?.insert(Data([0x1]), forKey: "a/b")
        try await cache?.insert(Data([0x2]), forKey: "ab")
        cache = nil

        let secondStore = try CacheStore<String, Data>.disk(
            id: "disk",
            configuration: configuration
        )
        let restored = try Cache(stores: [secondStore])

        let slashValue = try await restored.value(forKey: "a/b")
        let plainValue = try await restored.value(forKey: "ab")
        XCTAssertEqual(slashValue, Data([0x1]))
        XCTAssertEqual(plainValue, Data([0x2]))
    }

    func testDiskStoreUsesDedicatedTaskExecutor() async throws
    {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let probe = CacheTaskExecutorProbe()
        let valueCoder = CacheValueCoder<Data>(
            encode: { value in
                probe.recordCurrentExecutor()
                return value
            },
            decode: { data in
                probe.recordCurrentExecutor()
                return data
            }
        )
        let store = try CacheStore<String, Data>.disk(
            configuration: DiskCacheConfiguration(
                name: "task-executor-test",
                rootDirectory: rootDirectory,
                capacityPolicy: .unlimited,
                maximumUnusedInterval: nil
            ),
            keyEncoder: .utf8,
            valueCoder: valueCoder
        )
        let cache = try Cache(stores: [store])

        try await cache.insert(Data([0x1]), forKey: "value")
        let value = try await cache.value(forKey: "value")
        XCTAssertEqual(value, Data([0x1]))

        let snapshot = probe.snapshot()
        XCTAssertEqual(snapshot.observationCount, 2)
        XCTAssertEqual(snapshot.nonpreferredExecutorCount, 0)
    }

    func testDiskStorePreservesEntryMetadataAndExpiresValues() async throws
    {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let configuration = DiskCacheConfiguration(
            name: "disk-metadata-test",
            rootDirectory: rootDirectory,
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil
        )
        let storedAt = Date(timeIntervalSinceReferenceDate: 123_456.25)
        let expirationDate = Date.now.addingTimeInterval(60)
        var cache: Cache<String, Data>? = try Cache(stores: [
            try CacheStore.disk(configuration: configuration),
        ])
        try await cache?.insert(
            CacheEntry(
                Data([0x1]),
                storedAt: storedAt,
                expirationDate: expirationDate,
                cost: 17
            ),
            forKey: "metadata"
        )
        try await cache?.insert(
            Data([0x2]),
            forKey: "expired",
            expirationDate: .distantPast
        )
        cache = nil

        let restored = try Cache(stores: [
            try CacheStore.disk(configuration: configuration),
        ])
        let optionalHit = try await restored.hit(forKey: "metadata")
        let hit = try XCTUnwrap(optionalHit)
        let expired = try await restored.value(forKey: "expired")

        XCTAssertEqual(hit.value, Data([0x1]))
        XCTAssertEqual(hit.storeID, .disk)
        XCTAssertEqual(
            hit.entry.storedAt.timeIntervalSinceReferenceDate,
            storedAt.timeIntervalSinceReferenceDate,
            accuracy: 0.000_001
        )
        XCTAssertEqual(hit.entry.expirationDate, expirationDate)
        XCTAssertEqual(hit.entry.cost, 17)
        XCTAssertNil(expired)
    }

    func testDiskDirectoryCannotBelongToTwoLiveDispatchers() throws
    {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: rootDirectory) }

        let configuration = DiskCacheConfiguration(
            name: "shared-disk-test",
            rootDirectory: rootDirectory,
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil
        )
        let firstStore = try CacheStore<String, Data>.disk(
            id: "first",
            configuration: configuration
        )
        let firstCache = try Cache(stores: [firstStore])
        let secondStore = try CacheStore<String, Data>.disk(
            id: "second",
            configuration: configuration
        )

        try withExtendedLifetime(firstCache)
        {
            XCTAssertThrowsError(try Cache(stores: [secondStore])) { error in
                guard case let CacheError.storeAlreadyAttached(storeID) = error else
                {
                    return XCTFail("Unexpected error: \(error)")
                }
                XCTAssertEqual(storeID, "second")
            }
        }
    }
}
