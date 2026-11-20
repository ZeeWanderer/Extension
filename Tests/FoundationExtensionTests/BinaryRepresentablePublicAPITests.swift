//
//  BinaryRepresentablePublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation
import XCTest
import FoundationExtension

final class BinaryRepresentablePublicAPITests: XCTestCase {
    private struct PaddedNativeValue: SafeBinaryRepresentable, Equatable {
        let marker: UInt8
        let number: UInt64
    }

    private struct NoncontiguousUInt32Collection: BinaryRepresentableCollection, Equatable {
        private var storage: [UInt32]

        init<Values>(_ values: Values) where Values: Sequence, Values.Element == UInt32 {
            storage = Array(values)
        }

        init(_ buffer: UnsafeBufferPointer<UInt32>) {
            storage = Array(buffer)
        }

        var startIndex: Int { storage.startIndex }
        var endIndex: Int { storage.endIndex }

        subscript(position: Int) -> UInt32 {
            storage[position]
        }

        func index(after index: Int) -> Int {
            storage.index(after: index)
        }
    }

    func testScalarRoundTripsPreservePublicValues() {
        assertRoundTrip(Int8.min)
        assertRoundTrip(Int16.max)
        assertRoundTrip(Int32.min)
        assertRoundTrip(Int64.max)
        assertRoundTrip(UInt8.max)
        assertRoundTrip(UInt16.max)
        assertRoundTrip(UInt32.max)
        assertRoundTrip(UInt64.max)
        assertRoundTrip(Float16.pi)
        assertRoundTrip(Float.pi)
        assertRoundTrip(Double.pi)
        assertRoundTrip(false)
        assertRoundTrip(true)
    }

    func testFixedWidthIntegersUseTheirNativeBytes() {
        let unsigned = UInt32(0x0102_0304)
        let signed = Int16(-2)

        XCTAssertEqual(unsigned.data, withUnsafeBytes(of: unsigned) { Data($0) })
        XCTAssertEqual(signed.data, withUnsafeBytes(of: signed) { Data($0) })
    }

    func testFloatingPointRoundTripsPreserveBitPatterns() {
        let floatValues: [Float] = [0, -0, .infinity, -.infinity, .nan]
        let doubleValues: [Double] = [0, -0, .infinity, -.infinity, .nan]

        for value in floatValues {
            XCTAssertEqual(Float(data: value.data).bitPattern, value.bitPattern)
        }
        for value in doubleValues {
            XCTAssertEqual(Double(data: value.data).bitPattern, value.bitPattern)
        }
    }

    func testValidatedScalarLoadRejectsTruncatedData() {
        let encoded = UInt64.max.data

        XCTAssertNil(UInt64(validating: encoded.dropLast()))
    }

    func testValidatedLoadsAcceptBuffersLargeEnoughForTheRequestedType() {
        var scalar = UInt64.max.data
        scalar.append(0)
        let nativeValue = PaddedNativeValue(marker: 1, number: 2)
        var native = nativeValue.data
        native.append(0)

        XCTAssertEqual(UInt64(validating: scalar), .max)
        XCTAssertEqual(PaddedNativeValue(validating: native), nativeValue)
    }

    func testValidatedScalarLoadHandlesADataSlice() {
        let value: Int64 = 0x0102_0304_0506_0708
        var storage = Data([0xFF])
        storage.append(value.data)

        XCTAssertEqual(Int64(validating: storage.dropFirst()), value)
    }

    func testDataLoadingConveniencesMatchTheTypeInitializers() {
        let value: UInt32 = 0xDEAD_BEEF

        let loaded: UInt32 = value.data.load()
        let validated: UInt32? = value.data.saferLoad()

        XCTAssertEqual(loaded, value)
        XCTAssertEqual(validated, value)
    }

    func testSafeBinaryRepresentableUsesTheEntireNativeLayout() {
        let value = PaddedNativeValue(marker: 7, number: 42)

        XCTAssertEqual(value.data.count, MemoryLayout<PaddedNativeValue>.size)
        XCTAssertGreaterThan(
            value.data.count,
            MemoryLayout<UInt8>.size + MemoryLayout<UInt64>.size,
            "The current native format includes internal padding bytes"
        )
        XCTAssertEqual(PaddedNativeValue(validating: value.data), value)
    }

    func testArrayRoundTripsThroughCollectionConformance() {
        let values: [Int64] = [-8, -1, 0, 1, 8, .max]
        let expected = values.reduce(into: Data()) { result, value in
            result.append(value.data)
        }

        XCTAssertEqual(Array<Int64>(data: values.data), values)
        XCTAssertEqual(Array<Int64>(data: [Int64]().data), [])
        XCTAssertEqual(values.data, expected)
        XCTAssertEqual(values.data.count, values.count * MemoryLayout<Int64>.stride)
    }

    func testValidatedArrayRejectsPartialElements() {
        let values: [UInt32] = [1, 2, 3]
        let malformed = values.data.dropLast()

        XCTAssertNil(Array<UInt32>(validating: malformed))
    }

    func testExistingHeaderlessFixedWidthBytesRemainValid() {
        let values: [UInt32] = [1, 2, 3]
        let legacyBytes = values.withUnsafeBytes { Data($0) }

        XCTAssertEqual(values.data, legacyBytes)
        XCTAssertEqual(Array<UInt32>(validating: legacyBytes), values)
    }

    func testNoncontiguousCollectionsUseTheSafeCopyFallback() {
        let values = NoncontiguousUInt32Collection([1, 2, 3, 4])

        XCTAssertNil(values.withContiguousStorageIfAvailable { _ in true })
        XCTAssertEqual(NoncontiguousUInt32Collection(validating: values.data), values)
    }

    func testLegacyDataCollectionLoadOverloadsReadElements() {
        let words: [UInt32] = [42, 17, 42]
        let bytes = words.withUnsafeBufferPointer { Data(buffer: $0) }
        let array: [UInt32] = bytes.load()
        let set: Set<UInt32>? = bytes.saferLoad()
        XCTAssertEqual(array, words)
        XCTAssertEqual(set, Set(words))
        XCTAssertEqual(bytes.load(as: Set<UInt32>.self), Set(words))
        XCTAssertEqual(bytes.saferLoad(as: [UInt32].self), words)
        XCTAssertEqual(Data().load(as: [UInt32].self), [])
        XCTAssertNil(bytes.dropLast().saferLoad(as: [UInt32].self))
    }

    func testGenericBinaryLoadsDispatchToCollectionStorage() {
        func load<T: BinaryRepresentable>(_ type: T.Type, from bytes: Data) -> T { bytes.load() }
        func validate<T: BinaryRepresentable>(_ type: T.Type, from bytes: Data) -> T? { bytes.saferLoad() }
        let values = NoncontiguousUInt32Collection([1, 2, 3, 4])
        XCTAssertEqual(load(NoncontiguousUInt32Collection.self, from: values.data), values)
        XCTAssertEqual(validate([UInt32].self, from: Data()), [])
        XCTAssertNil(validate([UInt32].self, from: values.data.dropLast()))
    }

    func testSetRoundTripPreservesMembership() {
        let values: Set<Int64> = [-1, 0, 1, 2, 3]
        let legacyBytes = ContiguousArray(values).withUnsafeBufferPointer {
            Data(buffer: $0)
        }

        XCTAssertEqual(Set<Int64>(data: values.data), values)
        XCTAssertEqual(Set<Int64>(validating: legacyBytes), values)
        XCTAssertEqual(values.data.count, values.count * MemoryLayout<Int64>.stride)
    }

    func testEqualSetsRoundTripWithoutRequiringEqualPayloadOrder() {
        let ascending = Set(0..<32)
        var descending = Set<Int>()
        for value in (0..<32).reversed() {
            descending.insert(value)
        }

        XCTAssertEqual(ascending, descending)
        XCTAssertEqual(Set<Int>(validating: ascending.data), ascending)
        XCTAssertEqual(Set<Int>(validating: descending.data), descending)
    }

    func testSetLoadingAcceptsAnyOrderAndUsesSetMembershipSemantics() {
        let reversed = [UInt32(3), 2, 1].data
        let duplicate = [UInt32(1), 1, 2].data

        XCTAssertEqual(Set<UInt32>(validating: reversed), Set([1, 2, 3]))
        XCTAssertEqual(Set<UInt32>(validating: duplicate), Set([1, 2]))
    }

    func testSetCanRequestStablePayloadOrdering() {
        let first: Set<Int32> = [3, 1, 2]
        var second = Set<Int32>()
        [2, 3, 1].forEach { second.insert($0) }

        let firstAscending = first.stableData(sortedBy: <)
        let secondAscending = second.stableData(sortedBy: <)
        let descending = first.stableData(sortedBy: >)

        XCTAssertEqual(firstAscending, secondAscending)
        XCTAssertEqual(firstAscending, [Int32(1), 2, 3].data)
        XCTAssertEqual(descending, [Int32(3), 2, 1].data)
        XCTAssertEqual(Set<Int32>(validating: firstAscending), first)
        XCTAssertEqual(Set<Int32>(validating: descending), first)
    }

    private func assertRoundTrip<Value>(
        _ value: Value,
        file: StaticString = #filePath,
        line: UInt = #line
    ) where Value: BinaryRepresentable & Equatable {
        XCTAssertEqual(Value(data: value.data), value, file: file, line: line)
        XCTAssertEqual(Value(validating: value.data), value, file: file, line: line)
        XCTAssertEqual(value.data.count, MemoryLayout<Value>.size, file: file, line: line)
    }
}
