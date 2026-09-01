//
//  P_CacheRangeGateTests.swift
//
//
//  Created by zeewanderer on 13.08.2026.
//

@testable import FoundationExtension
import XCTest

@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
final class P_CacheRangeGateTests: XCTestCase
{
    func testDisjointReadAndWriteProceedWhileOverlappingReadWaits() async
    {
        let gate = P_CacheRangeGate()
        let firstWrite = await gate.acquire(.write(0..<16))

        let disjoint = Task { await gate.acquire(.read(16..<32)) }
        let overlapping = Task { await gate.acquire(.read(8..<24)) }

        let disjointLease = await disjoint.value
        await p_waitUntil { gate.p_waiterCount == 1 }
        XCTAssertFalse(overlapping.isCancelled)
        XCTAssertFalse(
            gate.p_isAcquired(
                overlappingRange: 8..<16,
                as: .read(8..<16)
            )
        )

        gate.release(firstWrite)
        let overlappingLease = await overlapping.value

        gate.release(disjointLease)
        gate.release(overlappingLease)
    }

    func testOverlappingReadsProceedTogetherAndWriterWaits() async
    {
        let gate = P_CacheRangeGate()
        let firstRead = await gate.acquire(.read(0..<32))
        let secondRead = await gate.acquire(.read(8..<16))
        let writer = Task { await gate.acquire(.write(12..<20)) }

        await p_waitUntil { gate.p_waiterCount == 1 }
        XCTAssertFalse(
            gate.p_isAcquired(
                overlappingRange: 12..<20,
                as: .write(12..<20)
            )
        )

        gate.release(firstRead)
        await p_waitUntil { gate.p_waiterCount == 1 }
        XCTAssertFalse(
            gate.p_isAcquired(
                overlappingRange: 12..<16,
                as: .write(12..<16)
            )
        )

        gate.release(secondRead)
        let writeLease = await writer.value
        gate.release(writeLease)
    }

    func testWholeWriteWaitsForEveryRangeAndBlocksNewRanges() async
    {
        let gate = P_CacheRangeGate()
        let firstRead = await gate.acquire(.read(0..<8))
        let wholeWriter = Task { await gate.acquire(.wholeWrite) }
        await p_waitUntil { gate.p_waiterCount == 1 }
        let laterDisjointRead = Task { await gate.acquire(.read(100..<108)) }

        await p_waitUntil { gate.p_waiterCount == 2 }
        XCTAssertFalse(gate.p_hasActiveWholeWrite)

        gate.release(firstRead)
        let wholeLease = await wholeWriter.value
        XCTAssertTrue(gate.p_hasActiveWholeWrite)

        gate.release(wholeLease)
        let laterLease = await laterDisjointRead.value
        gate.release(laterLease)
    }

    func testDisjointWritersCanProceedTogether() async
    {
        let gate = P_CacheRangeGate()
        let first = await gate.acquire(.write(0..<8))
        let second = await gate.acquire(.write(8..<16))

        XCTAssertTrue(gate.p_isAcquired(overlappingRange: 0..<8, as: .write(0..<8)))
        XCTAssertTrue(gate.p_isAcquired(overlappingRange: 8..<16, as: .write(8..<16)))

        gate.release(first)
        gate.release(second)
    }

    internal func p_waitUntil(
        _ condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async
    {
        for _ in 0..<10_000
        {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Condition did not become true", file: file, line: line)
    }
}
