//
//  CacheCancellationTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheCancellationTests: XCTestCase
{
    @MainActor
    func testCancelledWriteStillInvalidatesEveryBuiltInStore() async throws
    { try await p_checkCancelledWrite(targeted: false) }

    @MainActor
    func testCancelledTargetedWriteStillRestoresResidentCopies() async throws
    { try await p_checkCancelledWrite(targeted: true) }

    @MainActor
    func testCancelledResidencyLookupDoesNotStartATargetedMutation() async throws
    {
        let recorder = P_ConcurrencyContext.Recorder()
        let store = CacheStore<String, Int>(
            id: "store",
            retrieve: { _ in
                withUnsafeCurrentTask { $0?.cancel() }
                return CacheEntry(1)
            },
            store: { _, _ in recorder.record("store") },
            remove: { _ in recorder.record("remove") },
            removeAll: { recorder.record("removeAll") }
        )
        let cache = try Cache(stores: [store])

        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do
                {
                    try await cache.insert(2, forKey: "key", targeting: "store")
                    return false
                }
                catch is CancellationError { return true }
                catch { return false }
            }
            let wasCancelled = await group.next()
            XCTAssertEqual(wasCancelled, true)
        }

        XCTAssertTrue(recorder.snapshots.isEmpty)
    }

    @MainActor
    func p_checkCancelledWrite(targeted: Bool) async throws
    {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-cancel-rollback-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let pending = expectation(description: "mutation is waiting for cancellation")
        let storage = try DiskCacheStorage(
            location: .custom(directory),
            performsAutomaticMaintenance: false
        )
        let disk = try CacheStore<String, Int>.disk(
            storage: storage,
            keyEncoder: .utf8,
            valueCoder: .json
        )
        let failingStore = CacheStore<String, Int>(
            id: "failing",
            retrieve: { _ in CacheEntry(1) },
            store: { entry, _ in
                if entry.value == 2
                {
                    pending.fulfill()
                    try await Task.sleep(for: .seconds(30))
                }
            },
            remove: { _ in },
            removeAll: {}
        )
        let cache = try Cache(stores: [.memory(), disk, failingStore])
        try await cache.insert(1, forKey: "key")

        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do
                {
                    if targeted { try await cache.insert(2, forKey: "key", targeting: .disk) }
                    else { try await cache.insert(2, forKey: "key") }
                    return false
                }
                catch CacheError.storeFailures(let failures)
                {
                    return !failures.isEmpty && failures.allSatisfy { $0.operation != .rollback }
                }
                catch { return false }
            }
            await fulfillment(of: [pending], timeout: 2)
            group.cancelAll()
            let rollbackSucceeded = await group.next()
            XCTAssertEqual(rollbackSucceeded, true)
        }

        let diskValue = try await cache.value(forKey: "key", from: .disk)
        let memoryValue = try await cache.value(forKey: "key", from: .memory)
        XCTAssertEqual(diskValue, targeted ? 1 : nil)
        XCTAssertEqual(memoryValue, targeted ? 1 : nil)
    }

    @MainActor
    func testCancellingAMultiStoreReadCancelsAndJoinsEveryChild() async throws
    {
        let started = expectation(description: "both reads started")
        started.expectedFulfillmentCount = 2
        let recorder = P_ConcurrencyContext.Recorder()
        let stores = ["first", "second"].map { name in
            CacheStore<String, Int>(
                id: CacheStoreID(rawValue: name),
                retrieve: { _ in
                    started.fulfill()
                    defer { recorder.record(name) }
                    try await Task.sleep(for: .seconds(30))
                    return CacheEntry(42)
                },
                store: { _, _ in },
                remove: { _ in },
                removeAll: {}
            )
        }
        let cache = try Cache(stores: stores, route: .init(readStages: [["first", "second"]], writeStores: []))

        await P_ConcurrencyContext.$marker.withValue("read-parent") {
            await withTaskGroup(of: Bool.self) { group in
                group.addTask {
                    do
                    {
                        _ = try await cache.value(forKey: "key")
                        return false
                    }
                    catch is CancellationError { return true }
                    catch { return false }
                }
                await fulfillment(of: [started], timeout: 2)
                group.cancelAll()
                let cancelled = await group.next()
                XCTAssertEqual(cancelled, true)
                // Returning from the operation must also join the store tasks.
                XCTAssertEqual(recorder.snapshots.count, 2)
            }
        }
        XCTAssertTrue(recorder.snapshots.allSatisfy { $0.marker == "read-parent" })
    }
}
