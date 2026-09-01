//
//  CacheTargetedAccessTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class CacheTargetedAccessTests: XCTestCase
{
    func testTargetedReadDoesNotPromote() async throws
    {
        let memory = P_CacheIntStoreBackend(id: "memory")
        let disk = P_CacheIntStoreBackend(
            id: "disk",
            entries: ["value": CacheEntry(7)]
        )
        let cache = try Cache(stores: [
            memory.makeStore(),
            disk.makeStore(),
        ])

        let hit = try await cache.hit(forKey: "value", from: "disk")

        XCTAssertEqual(hit?.value, 7)
        XCTAssertEqual(hit?.storeID, "disk")
        XCTAssertNil(memory.entry(for: "value"))
        XCTAssertEqual(
            disk.eventSnapshot().map(\.operation),
            [.retrieve]
        )
    }

    func testTargetedWriteUpdatesRequestedAndResidentStoresOnly() async throws
    {
        let memory0 = P_CacheIntStoreBackend(
            id: "memory0",
            entries: ["value": CacheEntry(1)]
        )
        let memory1 = P_CacheIntStoreBackend(id: "memory1")
        let disk = P_CacheIntStoreBackend(
            id: "disk",
            entries: ["value": CacheEntry(1)]
        )
        let cache = try Cache(stores: [
            memory0.makeStore(),
            memory1.makeStore(),
            disk.makeStore(),
        ])

        try await cache.insert(2, forKey: "value", targeting: "disk")

        XCTAssertEqual(memory0.entry(for: "value")?.value, 2)
        XCTAssertNil(memory1.entry(for: "value"))
        XCTAssertEqual(disk.entry(for: "value")?.value, 2)
    }

    func testTargetedWriteTreatsExpiredCopiesAsAbsent() async throws
    {
        let memory = P_CacheIntStoreBackend(
            id: "memory",
            entries: [
                "value": CacheEntry(
                    1,
                    expirationDate: .distantPast
                ),
            ]
        )
        let disk = P_CacheIntStoreBackend(id: "disk")
        let cache = try Cache(stores: [
            memory.makeStore(),
            disk.makeStore(),
        ])

        try await cache.insert(2, forKey: "value", targeting: "disk")

        XCTAssertNil(memory.entry(for: "value"))
        XCTAssertEqual(disk.entry(for: "value")?.value, 2)
    }

    func testTargetedWriteAbortsBeforeMutationWhenResidencyReadFails() async throws
    {
        let memory = P_CacheIntStoreBackend(
            id: "memory",
            entries: ["value": CacheEntry(1)],
            failingOperations: [.retrieve]
        )
        let disk = P_CacheIntStoreBackend(
            id: "disk",
            entries: ["value": CacheEntry(1)]
        )
        let cache = try Cache(stores: [
            memory.makeStore(),
            disk.makeStore(),
        ])

        do
        {
            try await cache.insert(2, forKey: "value", targeting: "disk")
            XCTFail("The write should fail before changing any store")
        }
        catch let CacheError.storeFailures(failures)
        {
            XCTAssertEqual(failures.map(\.storeID), ["memory"])
            XCTAssertEqual(failures.map(\.operation), [.retrieve])
        }

        XCTAssertEqual(memory.entry(for: "value")?.value, 1)
        XCTAssertEqual(disk.entry(for: "value")?.value, 1)
        XCTAssertFalse(
            disk.eventSnapshot().contains { $0.operation == .store }
        )
    }

    func testFailedTargetedWriteRestoresPreviousResidency() async throws
    {
        let memory = P_CacheIntStoreBackend(
            id: "memory",
            entries: ["value": CacheEntry(1)]
        )
        let disk = P_CacheIntStoreBackend(
            id: "disk",
            entries: ["value": CacheEntry(1)],
            failingOperations: [.store]
        )
        let cache = try Cache(stores: [
            memory.makeStore(),
            disk.makeStore(),
        ])

        do
        {
            try await cache.insert(2, forKey: "value", targeting: "disk")
            XCTFail("The failing target should make the write fail")
        }
        catch let CacheError.storeFailures(failures)
        {
            XCTAssertEqual(failures.first?.storeID, "disk")
            XCTAssertEqual(failures.first?.operation, .store)
        }

        XCTAssertEqual(memory.entry(for: "value")?.value, 1)
        XCTAssertEqual(disk.entry(for: "value")?.value, 1)
    }

    func testSynchronousTargetedAccessPreservesResidentCopies() throws
    {
        let memory = P_CacheIntStoreBackend(
            id: "memory",
            entries: ["value": CacheEntry(1)]
        )
        let disk = P_CacheIntStoreBackend(
            id: "disk",
            entries: ["value": CacheEntry(1)]
        )
        let cache = try Cache(stores: [
            memory.makeStore(),
            disk.makeStore(),
        ])

        XCTAssertEqual(try cache.value(forKey: "value", from: "disk"), 1)
        try cache.insert(2, forKey: "value", targeting: "disk")

        XCTAssertEqual(memory.entry(for: "value")?.value, 2)
        XCTAssertEqual(disk.entry(for: "value")?.value, 2)
    }

    func testTargetedAccessValidatesStoreBeforeTouchingBackends() async throws
    {
        let backend = P_CacheIntStoreBackend(id: "known")
        let cache = try Cache(stores: [backend.makeStore()])

        do
        {
            _ = try await cache.value(forKey: "value", from: "missing")
            XCTFail("An unknown read store should fail")
        }
        catch CacheError.unknownStoreID("missing") {}

        do
        {
            try await cache.insert(1, forKey: "value", targeting: "missing")
            XCTFail("An unknown write store should fail")
        }
        catch CacheError.unknownStoreID("missing") {}

        XCTAssertTrue(backend.eventSnapshot().isEmpty)
    }
}
