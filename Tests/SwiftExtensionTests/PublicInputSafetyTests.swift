//
//  PublicInputSafetyTests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation
import XCTest
import SwiftExtension

final class SwiftInputSafetyPublicAPITests: XCTestCase {
    func testValidBoundaryInputsKeepTheirCurrentResults() {
        XCTAssertEqual([1, 2, 3].chunked(into: 1), [[1], [2], [3]])
        XCTAssertEqual(String("abc")[0...], "abc")
        XCTAssertEqual(String("abc")[...2], "abc")
        XCTAssertEqual(String("abc")[..<3], "abc")
        XCTAssertEqual(greatestCommonDivisor(0, 8), 8)
        XCTAssertEqual(leastCommonMultiple(0, 8), 0)
    }

    func testNonpositiveChunkSizesReturnNoChunks() {
        XCTAssertEqual([1, 2, 3].chunked(into: 0), [])
        XCTAssertEqual([1, 2, 3].chunked(into: -1), [])
    }

    func testEmptyStringPartialRangesAreEmpty() {
        let value = ""
        XCTAssertEqual(value[0...], "")
        XCTAssertEqual(value[...0], "")
        XCTAssertEqual(value[..<0], "")
    }

    func testLCMHandlesTwoZeroes() {
        XCTAssertEqual(leastCommonMultiple(0, 0), 0)
    }

    func testLCMDividesBeforeMultiplying() {
        let value = Int(ProcessInfo.processInfo.environment["EXTENSION_LCM_OPERAND"] ?? "") ?? .max
        XCTAssertEqual(leastCommonMultiple(value, value), value)
    }

    func testHashedHeapRejectsNegativeIndices() {
        var heap = HashedHeap(array: [1, 2, 3], sort: <)
        XCTAssertNil(heap.remove(at: -1))
        XCTAssertEqual(heap.elements.count, 3)
    }

    func testHeapRejectsNegativeIndices() {
        var heap = Heap(array: [1, 2, 3], sort: <)

        XCTAssertNil(heap.remove(at: -1))
        heap.replace(index: -1, value: 99)

        XCTAssertEqual(heap.count, 3)
        XCTAssertEqual(heap.remove(), 1)
    }

    func testSafeClosedArrayRangeHandlesEmptyStorage() {
        let values: [Int] = []

        XCTAssertEqual(Array(values[safe: 0...0]), [])
    }

    func testQueueCopiesHaveIndependentValueSemantics() {
        var original = Queue<Int>()
        original.enqueue(1)
        var copy = original

        _ = original.dequeue()
        copy.enqueue(2)

        XCTAssertNil(original.peek())
        XCTAssertEqual(copy.dequeue(), 1)
        XCTAssertEqual(copy.dequeue(), 2)
    }

    func testIntegerGCDAndLCMAreNonnegative() {
        XCTAssertEqual(greatestCommonDivisor(-6, -4), 2)
        XCTAssertEqual(greatestCommonDivisor(-6, 4), 2)
        XCTAssertEqual(leastCommonMultiple(-3, 4), 12)
        XCTAssertEqual(leastCommonMultiple(3, -4), 12)
    }

    func testSignedMinimumDoesNotOverflowAnIntermediateDivisor() {
        XCTAssertEqual(greatestCommonDivisor([Int.min, 0, 6]), 2)
        XCTAssertEqual(greatestCommonDivisor([6, Int.min]), 2)
        let fraction = lowestTerms(numerator: Int.min, denominator: Int.min)
        XCTAssertEqual(fraction.0, 1)
        XCTAssertEqual(fraction.1, 1)
    }
}
