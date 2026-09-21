//
//  CacheExecutionContextTests.swift
//
//
//  Created by zeewanderer on 10.09.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheExecutionContextTests: XCTestCase
{
    @MainActor
    func testEveryAsyncDispatcherEntryPointLeavesTheMainActorAndPreservesTaskOwnership() async throws
    {
        let recorder = P_ConcurrencyContext.Recorder()
        let store = CacheStore<String, Int>(
            id: "only",
            retrieve: { _ in
                recorder.record("retrieve")
                return CacheEntry(42)
            },
            store: { _, _ in recorder.record("store") },
            remove: { _ in recorder.record("remove") },
            removeAll: { recorder.record("removeAll") },
            maintenance: { _ in
                recorder.record("maintenance")
                return .unsupported
            }
        )
        let cache = try Cache(stores: [store], routeProvider: { _ in
            recorder.record("route")
            return .hierarchy(["only"])
        })
        let taskID = try XCTUnwrap(withUnsafeCurrentTask { $0?.hashValue })

        try await P_ConcurrencyContext.$marker.withValue("caller") {
            _ = try await cache.hit(forKey: "key")
            _ = try await cache.value(forKey: "key")
            _ = try await cache.hit(forKey: "key", from: "only")
            _ = try await cache.value(forKey: "key", from: "only")
            try await cache.insert(42, forKey: "key")
            try await cache.insert(CacheEntry(42), forKey: "key")
            try await cache.insert(42, forKey: "key", targeting: "only")
            try await cache.insert(CacheEntry(42), forKey: "key", targeting: "only")
            try await cache.removeValue(forKey: "key")
            try await cache.removeAll()
            _ = try await cache.performMaintenance()
        }

        let snapshots = recorder.snapshots
        XCTAssertEqual(Set(snapshots.map(\.operation)), ["retrieve", "store", "remove", "removeAll", "maintenance", "route"])
        for snapshot in snapshots
        {
            XCTAssertFalse(snapshot.isMainThread, snapshot.operation)
            XCTAssertEqual(snapshot.marker, "caller", snapshot.operation)
            if snapshot.operation != "maintenance"
            {
                XCTAssertEqual(snapshot.taskID, taskID, snapshot.operation)
            }
        }
        MainActor.assertIsolated()
    }

    @MainActor
    func testMemoryCostCalculationLeavesTheMainActorInTheSameTask() async throws
    {
        let recorder = P_ConcurrencyContext.Recorder()
        let cache = Cache<String, Int>(cost: { _ in
            recorder.record("cost")
            return 1
        })
        let taskID = try XCTUnwrap(withUnsafeCurrentTask { $0?.hashValue })

        try await cache.insert(42, forKey: "key")

        let snapshot = try XCTUnwrap(recorder.snapshots.first)
        XCTAssertFalse(snapshot.isMainThread)
        XCTAssertEqual(snapshot.taskID, taskID)
    }

    @MainActor
    func testSparseKeyEncodingLeavesTheMainActorInTheSameTask() async throws
    {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-sparse-context-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = try DiskCacheStorage(
            location: .custom(directory),
            performsAutomaticMaintenance: false
        )
        let recorder = P_ConcurrencyContext.Recorder()
        let cache = try SparseCache<String>(storage: storage, keyEncoder: .init { key in
            recorder.record("key")
            return Data(key.utf8)
        })
        let taskID = try XCTUnwrap(withUnsafeCurrentTask { $0?.hashValue })

        try await P_ConcurrencyContext.$marker.withValue("sparse-caller") {
            try await cache.prepare(capacity: 4, forKey: "key")
            try await cache.insert(Data([1, 2, 3, 4]), at: 0, forKey: "key")
            _ = try await cache.snapshot(forKey: "key")
            let bytes = try await cache.data(in: 0..<4, forKey: "key")
            XCTAssertEqual(bytes, Data([1, 2, 3, 4]))
            try await cache.synchronize(forKey: "key")
            try await cache.removeValue(forKey: "key")
            try await cache.removeAll()
            _ = try await storage.performMaintenance()
            try await storage.removeAll()
        }

        XCTAssertEqual(recorder.snapshots.count, 6)
        for snapshot in recorder.snapshots
        {
            XCTAssertFalse(snapshot.isMainThread)
            XCTAssertEqual(snapshot.taskID, taskID)
            XCTAssertEqual(snapshot.marker, "sparse-caller")
        }
        MainActor.assertIsolated()
    }
}
