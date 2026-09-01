//
//  SparseCacheFailureTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

import Darwin
import Foundation
@testable import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class SparseCacheFailureTests: XCTestCase
{
    func testFailedOverlappingInsertDoesNotAdvertiseUnwrittenGap() async throws
    {
        let root = try p_makeCacheTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = try DiskCacheStorage(
            name: "sparse-failure-tests",
            location: .custom(root),
            capacityPolicy: .unlimited,
            maximumUnusedInterval: nil,
            performsAutomaticMaintenance: false
        )
        let cache = try SparseCache<String>(storage: storage)
        _ = try await cache.prepare(capacity: 16, forKey: "video")
        _ = try await cache.insert(
            Data(repeating: 1, count: 4),
            at: 0,
            forKey: "video"
        )
        try await cache.synchronize(forKey: "video")

        let urls = try cache.p_fileURLs(for: "video")
        let resource = storage.p_coordinator.sparseResources.retain(
            dataURL: urls.data,
            manifestURL: urls.manifest
        )
        defer { storage.p_coordinator.sparseResources.release(resource) }
        _ = try resource.loadIfNeeded(fileManager: FileManager.default)
        try resource.stateLock.withLock {
            let readOnlyDescriptor = Darwin.open(
                urls.data.path,
                O_RDONLY | O_CLOEXEC
            )
            guard readOnlyDescriptor >= 0 else
            {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            Darwin.close(resource.fileDescriptor)
            resource.fileDescriptor = readOnlyDescriptor
        }

        do
        {
            _ = try await cache.insert(
                Data(repeating: 2, count: 6),
                at: 2,
                forKey: "video"
            )
            XCTFail("The injected read-only descriptor must reject a write")
        }
        catch is POSIXError {}

        resource.invalidate()
        let loaded = try await cache.snapshot(forKey: "video")
        let snapshot = try XCTUnwrap(loaded)
        XCTAssertEqual(snapshot.ranges, [0..<4])
        let uncertain = try await cache.data(in: 4..<8, forKey: "video")
        XCTAssertNil(uncertain)
    }
}
