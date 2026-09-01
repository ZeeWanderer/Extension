//
//  CacheConcurrencyTests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation
import XCTest
import FoundationExtension

private enum CacheConcurrencyProbeError: Error
{
    case timedOut(String)
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private actor CacheAsyncMutationProbe
{
    private var entries: [String: CacheEntry<Int>] = [:]
    private var activeMutationCount = 0
    private var maximumActiveMutationCount = 0
    private var mutationStartCount = 0
    private var mutationsAreHeld = true
    private var mutationWaiters: [CheckedContinuation<Void, Never>] = []

    func retrieve(for key: String) -> CacheEntry<Int>?
    {
        entries[key]
    }

    func store(_ entry: CacheEntry<Int>, for key: String) async
    {
        mutationStartCount += 1
        activeMutationCount += 1
        maximumActiveMutationCount = max(
            maximumActiveMutationCount,
            activeMutationCount
        )

        if mutationsAreHeld
        {
            await withCheckedContinuation { continuation in
                mutationWaiters.append(continuation)
            }
        }

        entries[key] = entry
        activeMutationCount -= 1
    }

    func remove(for key: String)
    {
        entries.removeValue(forKey: key)
    }

    func removeAll()
    {
        entries.removeAll()
    }

    func waitForMutationStarts(_ count: Int) async throws
    {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while mutationStartCount < count
        {
            guard clock.now < deadline else
            {
                throw CacheConcurrencyProbeError.timedOut("mutation")
            }
            await Task.yield()
        }
    }

    func mutationCounts() -> (started: Int, maximumActive: Int)
    {
        (mutationStartCount, maximumActiveMutationCount)
    }

    func releaseMutations()
    {
        mutationsAreHeld = false
        let waiters = mutationWaiters
        mutationWaiters.removeAll()
        for waiter in waiters
        {
            waiter.resume()
        }
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeAsyncMutationStore(
    _ probe: CacheAsyncMutationProbe
) -> CacheStore<String, Int>
{
    CacheStore(
        id: "probe",
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
private final class CacheSynchronousResult<Value>: @unchecked Sendable
{
    private let lock = NSLock()
    private var values: [String: Value] = [:]
    private var errors: [String] = []

    func set(_ value: Value, for key: String)
    {
        lock.lock()
        values[key] = value
        lock.unlock()
    }

    func record(_ error: any Error)
    {
        lock.lock()
        errors.append(String(describing: error))
        lock.unlock()
    }

    func snapshot() -> (values: [String: Value], errors: [String])
    {
        lock.lock()
        defer { lock.unlock() }
        return (values, errors)
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private final class CacheSynchronousReadProbe: @unchecked Sendable
{
    let readStarted = DispatchSemaphore(value: 0)
    let releaseRead = DispatchSemaphore(value: 0)

    private let entry = CacheEntry(7)

    func retrieve(for key: String) throws -> CacheEntry<Int>?
    {
        readStarted.signal()
        guard releaseRead.wait(timeout: .now() + 2) == .success else
        {
            throw CacheConcurrencyProbeError.timedOut("synchronous read")
        }
        return entry
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeSynchronousReadStore(
    _ probe: CacheSynchronousReadProbe
) -> CacheStore<String, Int>
{
    CacheStore(
        id: "probe",
        retrieve: { _ in CacheEntry(7) },
        store: { _, _ in },
        remove: { _ in },
        removeAll: {},
        synchronous: CacheStoreSynchronousOperations(
            retrieve: { key in
                try probe.retrieve(for: key)
            },
            store: { _, _ in },
            remove: { _ in },
            removeAll: {}
        )
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private final class CacheSynchronousWriteProbe: @unchecked Sendable
{
    let writeStarted = DispatchSemaphore(value: 0)
    let releaseWrite = DispatchSemaphore(value: 0)

    private let lock = NSLock()
    private var entries: [String: CacheEntry<Int>] = [:]

    func retrieve(for key: String) -> CacheEntry<Int>?
    {
        lock.lock()
        defer { lock.unlock() }
        return entries[key]
    }

    func store(_ entry: CacheEntry<Int>, for key: String) throws
    {
        writeStarted.signal()
        guard releaseWrite.wait(timeout: .now() + 2) == .success else
        {
            throw CacheConcurrencyProbeError.timedOut("synchronous write")
        }
        lock.lock()
        entries[key] = entry
        lock.unlock()
    }

    func storeImmediately(_ entry: CacheEntry<Int>, for key: String)
    {
        lock.lock()
        entries[key] = entry
        lock.unlock()
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeSynchronousWriteStore(
    _ probe: CacheSynchronousWriteProbe
) -> CacheStore<String, Int>
{
    CacheStore(
        id: "probe",
        retrieve: { key in
            probe.retrieve(for: key)
        },
        store: { entry, key in
            probe.storeImmediately(entry, for: key)
        },
        remove: { _ in },
        removeAll: {},
        synchronous: CacheStoreSynchronousOperations(
            retrieve: { key in
                probe.retrieve(for: key)
            },
            store: { entry, key in
                try probe.store(entry, for: key)
            },
            remove: { _ in },
            removeAll: {}
        )
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private final class CacheSynchronousBarrierProbe: @unchecked Sendable
{
    let firstReadStarted = DispatchSemaphore(value: 0)
    let releaseFirstRead = DispatchSemaphore(value: 0)
    let writeStarted = DispatchSemaphore(value: 0)
    let releaseWrite = DispatchSemaphore(value: 0)
    let secondReadStarted = DispatchSemaphore(value: 0)

    private let lock = NSLock()
    private var entry = CacheEntry(1)
    private var readCount = 0
    private var events: [String] = []

    func retrieve(for key: String) throws -> CacheEntry<Int>?
    {
        let read: Int
        let result: CacheEntry<Int>
        lock.lock()
        readCount += 1
        read = readCount
        result = entry
        events.append("read-\(read)-start")
        lock.unlock()

        if read == 1
        {
            firstReadStarted.signal()
            guard releaseFirstRead.wait(timeout: .now() + 2) == .success else
            {
                throw CacheConcurrencyProbeError.timedOut("first read")
            }
        }
        else
        {
            secondReadStarted.signal()
        }

        lock.lock()
        events.append("read-\(read)-end")
        lock.unlock()
        return result
    }

    func store(_ entry: CacheEntry<Int>, for key: String) throws
    {
        lock.lock()
        events.append("write-start")
        lock.unlock()
        writeStarted.signal()

        guard releaseWrite.wait(timeout: .now() + 2) == .success else
        {
            throw CacheConcurrencyProbeError.timedOut("barrier write")
        }

        lock.lock()
        self.entry = entry
        events.append("write-end")
        lock.unlock()
    }

    func eventSnapshot() -> [String]
    {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    func retrieveImmediately() -> CacheEntry<Int>
    {
        lock.lock()
        defer { lock.unlock() }
        return entry
    }

    func storeImmediately(_ entry: CacheEntry<Int>)
    {
        lock.lock()
        self.entry = entry
        lock.unlock()
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeSynchronousBarrierStore(
    _ probe: CacheSynchronousBarrierProbe
) -> CacheStore<String, Int>
{
    CacheStore(
        id: "probe",
        retrieve: { _ in
            probe.retrieveImmediately()
        },
        store: { entry, _ in
            probe.storeImmediately(entry)
        },
        remove: { _ in },
        removeAll: {},
        synchronous: CacheStoreSynchronousOperations(
            retrieve: { key in
                try probe.retrieve(for: key)
            },
            store: { entry, key in
                try probe.store(entry, for: key)
            },
            remove: { _ in },
            removeAll: {}
        )
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private final class CacheMixedAccessProbe: @unchecked Sendable
{
    private let lock = NSLock()
    private var entry = CacheEntry(1)
    private var events: [String] = []
    private var firstReadContinuation: CheckedContinuation<Void, Never>?
    private var readCount = 0
    private var writerWasStarted = false

    func retrieve(for key: String) async -> CacheEntry<Int>?
    {
        let (read, result) = lock.withLock {
            readCount += 1
            events.append("async-read-\(readCount)-start")
            return (readCount, entry)
        }

        if read == 1
        {
            await withCheckedContinuation { continuation in
                lock.lock()
                firstReadContinuation = continuation
                lock.unlock()
            }
        }

        lock.withLock {
            events.append("async-read-\(read)-end")
        }
        return result
    }

    func retrieveSynchronously(for key: String) -> CacheEntry<Int>?
    {
        lock.lock()
        defer { lock.unlock() }
        return entry
    }

    func store(_ entry: CacheEntry<Int>, for key: String)
    {
        lock.lock()
        events.append("sync-write-start")
        self.entry = entry
        events.append("sync-write-end")
        lock.unlock()
    }

    func markWriterStarted()
    {
        lock.lock()
        writerWasStarted = true
        lock.unlock()
    }

    func waitForFirstRead() async throws
    {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while true
        {
            let didStart = lock.withLock {
                firstReadContinuation != nil
            }
            if didStart { return }
            guard clock.now < deadline else
            {
                throw CacheConcurrencyProbeError.timedOut("mixed async read")
            }
            await Task.yield()
        }
    }

    func waitForWriterAttempt() async throws
    {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while true
        {
            let didStart = lock.withLock {
                writerWasStarted
            }
            if didStart { return }
            guard clock.now < deadline else
            {
                throw CacheConcurrencyProbeError.timedOut("mixed sync write")
            }
            await Task.yield()
        }
    }

    func releaseFirstRead()
    {
        lock.lock()
        let continuation = firstReadContinuation
        firstReadContinuation = nil
        lock.unlock()
        continuation?.resume()
    }

    func eventSnapshot() -> [String]
    {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func makeMixedAccessStore(
    _ probe: CacheMixedAccessProbe
) -> CacheStore<String, Int>
{
    CacheStore(
        id: "probe",
        retrieve: { key in
            await probe.retrieve(for: key)
        },
        store: { entry, key in
            probe.store(entry, for: key)
        },
        remove: { _ in },
        removeAll: {},
        synchronous: CacheStoreSynchronousOperations(
            retrieve: { key in
                probe.retrieveSynchronously(for: key)
            },
            store: { entry, key in
                probe.store(entry, for: key)
            },
            remove: { _ in },
            removeAll: {}
        )
    )
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
private func waitForDispatchGroup(_ group: DispatchGroup) async
{
    await withCheckedContinuation { continuation in
        group.notify(queue: .global()) {
            continuation.resume()
        }
    }
}

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheConcurrencyTests: XCTestCase
{
    func testConcurrentAsyncWritesForTheSameKeyAreSerialized() async throws
    {
        let probe = CacheAsyncMutationProbe()
        let cache = try Cache(stores: [makeAsyncMutationStore(probe)])
        let writeCount = 32

        let writes = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for value in 0..<writeCount
                {
                    group.addTask {
                        try await cache.insert(value, forKey: "same")
                    }
                }
                try await group.waitForAll()
            }
        }

        try await probe.waitForMutationStarts(1)
        for _ in 0..<100
        {
            await Task.yield()
        }
        let heldCounts = await probe.mutationCounts()
        XCTAssertEqual(heldCounts.started, 1)
        XCTAssertEqual(heldCounts.maximumActive, 1)

        await probe.releaseMutations()
        try await writes.value

        let finalCounts = await probe.mutationCounts()
        let value = try await cache.value(forKey: "same")
        XCTAssertEqual(finalCounts.started, writeCount)
        XCTAssertEqual(finalCounts.maximumActive, 1)
        XCTAssertTrue((0..<writeCount).contains(try XCTUnwrap(value)))
    }

    func testConcurrentAsyncWritesForDifferentKeysCanOverlap() async throws
    {
        let probe = CacheAsyncMutationProbe()
        let cache = try Cache(stores: [makeAsyncMutationStore(probe)])

        async let first: Void = cache.insert(1, forKey: "first")
        async let second: Void = cache.insert(2, forKey: "second")

        try await probe.waitForMutationStarts(2)
        let heldCounts = await probe.mutationCounts()
        XCTAssertEqual(heldCounts.started, 2)
        XCTAssertEqual(heldCounts.maximumActive, 2)

        await probe.releaseMutations()
        _ = try await (first, second)
        let firstValue = try await cache.value(forKey: "first")
        let secondValue = try await cache.value(forKey: "second")
        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 2)
    }

    func testConcurrentAsyncMemoryOperationsPreservePerKeyValues() async throws
    {
        let cache = Cache<Int, Int>()
        let workerCount = 64
        let iterations = 50

        let valuesAreConsistent = try await withThrowingTaskGroup(
            of: Bool.self,
            returning: Bool.self
        ) { group in
            for worker in 0..<workerCount
            {
                group.addTask {
                    for value in 0..<iterations
                    {
                        try await cache.insert(value, forKey: worker)
                        guard try await cache.value(forKey: worker) == value else { return false }
                    }
                    try await cache.removeValue(forKey: worker)
                    return try await cache.value(forKey: worker) == nil
                }
            }

            for try await valueIsConsistent in group
            {
                guard valueIsConsistent else { return false }
            }
            return true
        }

        XCTAssertTrue(valuesAreConsistent)
    }

    func testSynchronousReadsForTheSameKeyCanOverlap() throws
    {
        let probe = CacheSynchronousReadProbe()
        let cache = try Cache(stores: [makeSynchronousReadStore(probe)])
        let results = CacheSynchronousResult<Int?>()
        let group = DispatchGroup()

        for read in 0..<2
        {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                do
                {
                    results.set(
                        try cache.value(forKey: "same"),
                        for: String(read)
                    )
                }
                catch
                {
                    results.record(error)
                }
            }
        }

        let firstStarted = probe.readStarted.wait(
            timeout: .now() + 2
        ) == .success
        let secondStarted = probe.readStarted.wait(
            timeout: .now() + 2
        ) == .success
        probe.releaseRead.signal()
        probe.releaseRead.signal()

        XCTAssertTrue(firstStarted)
        XCTAssertTrue(secondStarted)
        XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
        let snapshot = results.snapshot()
        XCTAssertTrue(snapshot.errors.isEmpty)
        XCTAssertEqual(snapshot.values.count, 2)
        XCTAssertTrue(snapshot.values.values.allSatisfy { $0 == 7 })
    }

    func testSynchronousWriteIsABarrierForTheSameKey() throws
    {
        let probe = CacheSynchronousBarrierProbe()
        let cache = try Cache(stores: [makeSynchronousBarrierStore(probe)])
        let results = CacheSynchronousResult<Int?>()
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            do
            {
                results.set(
                    try cache.value(forKey: "same"),
                    for: "first"
                )
            }
            catch
            {
                results.record(error)
            }
        }
        XCTAssertEqual(
            probe.firstReadStarted.wait(timeout: .now() + 2),
            .success
        )

        group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            do
            {
                try cache.insert(2, forKey: "same")
            }
            catch
            {
                results.record(error)
            }
        }
        XCTAssertEqual(
            probe.writeStarted.wait(timeout: .now() + 0.05),
            .timedOut
        )

        probe.releaseFirstRead.signal()
        XCTAssertEqual(
            probe.writeStarted.wait(timeout: .now() + 2),
            .success
        )

        group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            do
            {
                results.set(
                    try cache.value(forKey: "same"),
                    for: "second"
                )
            }
            catch
            {
                results.record(error)
            }
        }
        XCTAssertEqual(
            probe.secondReadStarted.wait(timeout: .now() + 0.05),
            .timedOut
        )

        probe.releaseWrite.signal()
        XCTAssertEqual(
            probe.secondReadStarted.wait(timeout: .now() + 2),
            .success
        )
        XCTAssertEqual(group.wait(timeout: .now() + 2), .success)

        let snapshot = results.snapshot()
        XCTAssertTrue(snapshot.errors.isEmpty)
        XCTAssertEqual(snapshot.values["first"]!, 1)
        XCTAssertEqual(snapshot.values["second"]!, 2)
        XCTAssertEqual(probe.eventSnapshot(), [
            "read-1-start",
            "read-1-end",
            "write-start",
            "write-end",
            "read-2-start",
            "read-2-end",
        ])
    }

    func testSynchronousWritesForDifferentKeysCanOverlap() throws
    {
        let probe = CacheSynchronousWriteProbe()
        let cache = try Cache(stores: [makeSynchronousWriteStore(probe)])
        let results = CacheSynchronousResult<Int?>()
        let group = DispatchGroup()

        for (key, value) in [("first", 1), ("second", 2)]
        {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                do
                {
                    try cache.insert(value, forKey: key)
                }
                catch
                {
                    results.record(error)
                }
            }
        }

        let firstStarted = probe.writeStarted.wait(
            timeout: .now() + 2
        ) == .success
        let secondStarted = probe.writeStarted.wait(
            timeout: .now() + 2
        ) == .success
        probe.releaseWrite.signal()
        probe.releaseWrite.signal()

        XCTAssertTrue(firstStarted)
        XCTAssertTrue(secondStarted)
        XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
        let snapshot = results.snapshot()
        XCTAssertTrue(snapshot.errors.isEmpty)
        XCTAssertEqual(try cache.value(forKey: "first"), 1)
        XCTAssertEqual(try cache.value(forKey: "second"), 2)
    }

    func testSynchronousWriteWaitsForAnAsyncReadOfTheSameKey() async throws
    {
        let probe = CacheMixedAccessProbe()
        let cache = try Cache(stores: [makeMixedAccessStore(probe)])
        let synchronousResult = CacheSynchronousResult<Bool>()
        let group = DispatchGroup()

        let read = Task {
            try await cache.value(forKey: "same")
        }
        try await probe.waitForFirstRead()

        group.enter()
        DispatchQueue.global().async {
            defer { group.leave() }
            probe.markWriterStarted()
            do
            {
                try cache.insert(2, forKey: "same")
                synchronousResult.set(true, for: "write")
            }
            catch
            {
                synchronousResult.record(error)
            }
        }
        try await probe.waitForWriterAttempt()
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(
            probe.eventSnapshot(),
            ["async-read-1-start"]
        )

        probe.releaseFirstRead()
        let firstValue = try await read.value
        XCTAssertEqual(firstValue, 1)
        await waitForDispatchGroup(group)

        let synchronousSnapshot = synchronousResult.snapshot()
        XCTAssertTrue(synchronousSnapshot.errors.isEmpty)
        XCTAssertEqual(synchronousSnapshot.values["write"], true)
        let secondValue = try await cache.value(forKey: "same")
        XCTAssertEqual(secondValue, 2)
        XCTAssertEqual(probe.eventSnapshot(), [
            "async-read-1-start",
            "async-read-1-end",
            "sync-write-start",
            "sync-write-end",
            "async-read-2-start",
            "async-read-2-end",
        ])
    }

    func testConcurrentSynchronousMemoryOperationsPreservePerKeyValues() throws
    {
        let cache = Cache<Int, Int>()
        let errors = CacheSynchronousResult<Bool>()
        let group = DispatchGroup()
        let workerCount = 32
        let iterations = 50

        for worker in 0..<workerCount
        {
            group.enter()
            DispatchQueue.global().async {
                defer { group.leave() }
                do
                {
                    for value in 0..<iterations
                    {
                        try cache.insert(value, forKey: worker)
                        guard try cache.value(forKey: worker) == value else
                        {
                            errors.set(false, for: String(worker))
                            return
                        }
                    }
                    try cache.removeValue(forKey: worker)
                    errors.set(
                        try cache.value(forKey: worker) == nil,
                        for: String(worker)
                    )
                }
                catch
                {
                    errors.record(error)
                }
            }
        }

        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
        let snapshot = errors.snapshot()
        XCTAssertTrue(snapshot.errors.isEmpty)
        XCTAssertEqual(snapshot.values.count, workerCount)
        XCTAssertTrue(snapshot.values.values.allSatisfy { $0 })
    }

    func testSynchronousRoutingPromotionAndRemoval() throws
    {
        let promoted = CacheStore<String, Int>.memory(id: "promoted")
        let source = CacheStore<String, Int>.memory(id: "source")
        let cache = try Cache(stores: [promoted, source])
        let sourceRoute = CacheRoute(
            readStages: [["source"]],
            writeStores: ["source"],
            promotions: ["source": ["promoted"]]
        )
        let entry = CacheEntry(
            11,
            expirationDate: .distantFuture,
            cost: 17
        )

        try cache.insert(entry, forKey: "value", route: sourceRoute)
        let hit = try XCTUnwrap(
            cache.hit(forKey: "value", route: sourceRoute)
        )
        XCTAssertEqual(hit.value, 11)
        XCTAssertEqual(hit.storeID, "source")
        XCTAssertEqual(hit.entry.cost, 17)
        XCTAssertEqual(
            try cache.value(
                forKey: "value",
                route: CacheRoute(readStages: [["promoted"]])
            ),
            11
        )

        try cache.removeValue(forKey: "value")
        XCTAssertNil(try cache.value(forKey: "value", route: sourceRoute))

        try cache.insert(1, forKey: "first")
        try cache.insert(2, forKey: "second")
        try cache.removeAll()
        XCTAssertNil(try cache.value(forKey: "first"))
        XCTAssertNil(try cache.value(forKey: "second"))
    }
}
