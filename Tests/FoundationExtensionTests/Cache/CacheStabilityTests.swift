//
//  CacheStabilityTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheStabilityTests: XCTestCase
{
    func testSynchronousOperationsMatchADeterministicReferenceModel() throws
    {
        let backend = P_CacheIntStoreBackend(id: "model")
        let cache = try Cache(stores: [backend.makeStore()])
        var model: [String: Int] = [:]
        var generator = P_CacheSeededGenerator(seed: 0x51a8_1e)

        for operation in 0..<20_000
        {
            let key = String(Int.random(in: 0..<257, using: &generator))
            switch Int.random(in: 0..<20, using: &generator)
            {
            case 0..<9:
                let value = Int(truncatingIfNeeded: generator.next())
                try cache.insert(value, forKey: key)
                model[key] = value
            case 9..<13:
                try cache.removeValue(forKey: key)
                model.removeValue(forKey: key)
            case 13..<17:
                XCTAssertEqual(try cache.value(forKey: key), model[key])
            case 17..<19:
                let hit = try cache.hit(forKey: key)
                XCTAssertEqual(hit?.value, model[key])
                XCTAssertEqual(hit?.storeID, model[key] == nil ? nil : "model")
            default:
                if operation.isMultiple(of: 997)
                {
                    try cache.removeAll()
                    model.removeAll()
                }
                else
                {
                    XCTAssertEqual(try cache.value(forKey: key), model[key])
                }
            }
        }

        for key in 0..<257
        {
            XCTAssertEqual(
                try cache.value(forKey: String(key)),
                model[String(key)]
            )
        }
    }

    func testAsyncOperationsMatchADeterministicReferenceModel() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "model")
        let cache = try Cache(stores: [backend.makeStore()])
        var model: [String: Int] = [:]
        var generator = P_CacheSeededGenerator(seed: 0xcac4_e123)

        for operation in 0..<10_000
        {
            let key = String(Int.random(in: 0..<193, using: &generator))
            switch Int.random(in: 0..<20, using: &generator)
            {
            case 0..<9:
                let value = Int(truncatingIfNeeded: generator.next())
                try await cache.insert(value, forKey: key)
                model[key] = value
            case 9..<13:
                try await cache.removeValue(forKey: key)
                model.removeValue(forKey: key)
            case 13..<17:
                let value = try await cache.value(forKey: key)
                XCTAssertEqual(value, model[key])
            case 17..<19:
                let hit = try await cache.hit(forKey: key)
                XCTAssertEqual(hit?.value, model[key])
                XCTAssertEqual(hit?.storeID, model[key] == nil ? nil : "model")
            default:
                if operation.isMultiple(of: 701)
                {
                    try await cache.removeAll()
                    model.removeAll()
                }
                else
                {
                    let value = try await cache.value(forKey: key)
                    XCTAssertEqual(value, model[key])
                }
            }
        }

        for key in 0..<193
        {
            let value = try await cache.value(forKey: String(key))
            XCTAssertEqual(value, model[String(key)])
        }
    }

    func testReadFailurePolicyCanFallThroughOrFailFast() async throws
    {
        let failing = P_CacheIntStoreBackend(
            id: "failing",
            failingOperations: [.retrieve]
        )
        let source = P_CacheIntStoreBackend(
            id: "source",
            entries: ["key": CacheEntry(17)]
        )
        let cache = try Cache(stores: [
            failing.makeStore(),
            source.makeStore(),
        ])
        let ignoring = CacheRoute(
            readStages: [["failing"], ["source"]],
            readFailurePolicy: .ignore
        )
        let ignoredFailureValue = try await cache.value(
            forKey: "key",
            route: ignoring
        )
        XCTAssertEqual(ignoredFailureValue, 17)

        failing.resetEvents()
        source.resetEvents()
        let failingRoute = CacheRoute(
            readStages: [["failing"], ["source"]],
            readFailurePolicy: .fail
        )
        do
        {
            _ = try await cache.value(forKey: "key", route: failingRoute)
            XCTFail("Expected the first read stage to fail")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(failures.map(\.storeID), ["failing"])
            XCTAssertEqual(failures.map(\.operation), [.retrieve])
        }
        XCTAssertTrue(source.eventSnapshot().isEmpty)
    }

    func testFailureInAConcurrentReadStageWinsOverAHitWhenConfigured() async throws
    {
        let failing = P_CacheIntStoreBackend(
            id: "failing",
            failingOperations: [.retrieve]
        )
        let source = P_CacheIntStoreBackend(
            id: "source",
            entries: ["key": CacheEntry(9)]
        )
        let cache = try Cache(stores: [
            failing.makeStore(),
            source.makeStore(),
        ])
        let route = CacheRoute(
            readStages: [["failing", "source"]],
            readFailurePolicy: .fail
        )

        do
        {
            _ = try await cache.hit(forKey: "key", route: route)
            XCTFail("Expected a stage failure")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(failures.map(\.storeID), ["failing"])
            XCTAssertEqual(failures.map(\.operation), [.retrieve])
        }
    }

    func testFailedWriteRemovesPartialAndPreviousValuesFromEveryStore() async throws
    {
        let first = P_CacheIntStoreBackend(
            id: "first",
            entries: ["key": CacheEntry(1)]
        )
        let failing = P_CacheIntStoreBackend(
            id: "failing",
            entries: ["key": CacheEntry(1)],
            failingOperations: [.store]
        )
        let third = P_CacheIntStoreBackend(
            id: "third",
            entries: ["key": CacheEntry(1)]
        )
        let cache = try Cache(stores: [
            first.makeStore(),
            failing.makeStore(),
            third.makeStore(),
        ])

        do
        {
            try await cache.insert(2, forKey: "key")
            XCTFail("Expected the write to fail")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(failures.map(\.storeID), ["failing"])
            XCTAssertEqual(failures.map(\.operation), [.store])
        }
        XCTAssertNil(first.entry(for: "key"))
        XCTAssertNil(failing.entry(for: "key"))
        XCTAssertNil(third.entry(for: "key"))
    }

    func testRollbackFailuresAreAppendedInStoreOrder() async throws
    {
        let first = P_CacheIntStoreBackend(
            id: "first",
            failingOperations: [.remove]
        )
        let second = P_CacheIntStoreBackend(
            id: "second",
            failingOperations: [.store, .remove]
        )
        let third = P_CacheIntStoreBackend(
            id: "third",
            failingOperations: [.remove]
        )
        let cache = try Cache(stores: [
            first.makeStore(),
            second.makeStore(),
            third.makeStore(),
        ])

        do
        {
            try await cache.insert(1, forKey: "key")
            XCTFail("Expected write and rollback failures")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(
                failures.map(\.storeID.rawValue),
                ["second", "first", "second", "third"]
            )
            XCTAssertEqual(
                failures.map(\.operation),
                [.store, .rollback, .rollback, .rollback]
            )
        }
    }

    func testRemoveAndRemoveAllAggregateFailuresInStoreOrder() async throws
    {
        let stores = (0..<4).map { index in
            P_CacheIntStoreBackend(
                id: CacheStoreID(rawValue: "store-\(index)"),
                failingOperations: [.remove, .removeAll]
            )
        }
        let cache = try Cache(stores: stores.map { $0.makeStore() })

        do
        {
            try await cache.removeValue(forKey: "key")
            XCTFail("Expected remove failures")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(
                failures.map(\.storeID.rawValue),
                (0..<4).map { "store-\($0)" }
            )
            XCTAssertTrue(failures.allSatisfy { $0.operation == .remove })
        }

        do
        {
            try await cache.removeAll()
            XCTFail("Expected remove-all failures")
        }
        catch
        {
            let failures = try p_cacheStoreFailures(from: error)
            XCTAssertEqual(
                failures.map(\.storeID.rawValue),
                (0..<4).map { "store-\($0)" }
            )
            XCTAssertTrue(failures.allSatisfy { $0.operation == .removeAll })
        }
    }

    func testSynchronousFailuresHaveTheSameOrderingContract() throws
    {
        let stores = (0..<3).map { index in
            P_CacheIntStoreBackend(
                id: CacheStoreID(rawValue: "store-\(index)"),
                failingOperations: [.remove]
            )
        }
        let cache = try Cache(stores: stores.map { $0.makeStore() })

        XCTAssertThrowsError(try cache.removeValue(forKey: "key")) { error in
            do
            {
                let failures = try p_cacheStoreFailures(from: error)
                XCTAssertEqual(
                    failures.map(\.storeID.rawValue),
                    ["store-0", "store-1", "store-2"]
                )
                XCTAssertTrue(failures.allSatisfy { $0.operation == .remove })
            }
            catch {}
        }
    }

    func testExpiredEntriesAreMissesAndMemoryStoreEvictsThem() async throws
    {
        let cache = Cache<String, Int>()
        try await cache.insert(
            1,
            forKey: "expired",
            expirationDate: .distantPast
        )
        let expiredHit = try await cache.hit(forKey: "expired")
        XCTAssertNil(expiredHit)
        let expiredValue = try p_valueSynchronously(
            from: cache,
            forKey: "expired"
        )
        XCTAssertNil(expiredValue)

        let future = Date.now.addingTimeInterval(60)
        try await cache.insert(
            CacheEntry(2, expirationDate: future, cost: 14),
            forKey: "valid"
        )
        let optionalHit = try await cache.hit(forKey: "valid")
        let hit = try XCTUnwrap(optionalHit)
        XCTAssertEqual(hit.value, 2)
        XCTAssertEqual(hit.entry.expirationDate, future)
        XCTAssertEqual(hit.entry.cost, 14)
        XCTAssertEqual(hit.storeID, .memory)
    }

    func testEmptyReadStagesAndReadOnlyRoutesAreValidMissConfigurations() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "store")
        let cache = try Cache(stores: [backend.makeStore()])
        let route = CacheRoute(readStages: [[], []], writeStores: ["store"])

        try await cache.insert(5, forKey: "key", route: route)
        let hit = try await cache.hit(forKey: "key", route: route)
        XCTAssertNil(hit)
        XCTAssertTrue(
            backend.eventSnapshot().allSatisfy { $0.operation != .retrieve }
        )
    }
}
