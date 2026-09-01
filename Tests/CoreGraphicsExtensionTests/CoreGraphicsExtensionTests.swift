//
//  CoreGraphicsExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import CoreGraphics
import XCTest
import CoreGraphicsExtension

#if canImport(CoreGraphics)
final class CoreGraphicsPublicAPITests: XCTestCase {
    func testUnionMatchesPairwiseCoreGraphicsUnion() {
        let rectangles = [
            CGRect(x: 0, y: 0, width: 100, height: 100),
            CGRect(x: 300, y: 300, width: 100, height: 100),
            CGRect(x: 1_000, y: 200, width: 100, height: 100),
        ]

        let expected = rectangles.dropFirst().reduce(rectangles[0]) { $0.union($1) }

        XCTAssertEqual(union(rectangles), expected)
        XCTAssertEqual(rectangles[0].union(Array(rectangles.dropFirst())), expected)
        XCTAssertTrue(union([]).isNull)
    }

    func testNumeric2DOperatorsApplyToEachCoordinate() {
        let point = CGPoint(x: 2, y: 3)
        let size = CGSize(width: 4, height: 5)

        XCTAssertEqual(point.dot(size), 23)
        XCTAssertEqual(point.hadamard(size), CGPoint(x: 8, y: 15))

        let quotient = point.hadamardDivide(size)
        XCTAssertEqual(quotient.x, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(quotient.y, 0.6, accuracy: 0.000_001)
        XCTAssertEqual(point.scaled(x: 4, y: 5), CGPoint(x: 8, y: 15))
    }

    func testNumeric2DCrossTypeArithmeticPreservesTheLeftHandType() {
        let point = CGPoint(x: 6, y: 8)
        let size = CGSize(width: 2, height: 4)
        let vector = CGVector(dx: 3, dy: 2)

        XCTAssertEqual(point + size, CGPoint(x: 8, y: 12))
        XCTAssertEqual(size - vector, CGSize(width: -1, height: 2))
        XCTAssertEqual(vector + 2, CGVector(dx: 5, dy: 4))
        XCTAssertEqual(point - 2, CGPoint(x: 4, y: 6))
        XCTAssertEqual(point * 2, CGPoint(x: 12, y: 16))
        XCTAssertEqual(point / 2, CGPoint(x: 3, y: 4))
        XCTAssertEqual(-vector, CGVector(dx: -3, dy: -2))
        XCTAssertEqual(point.dot(vector), 34)
        XCTAssertEqual(point.hadamard(vector), CGPoint(x: 18, y: 16))
        XCTAssertEqual(point.hadamardDivide(size), CGPoint(x: 3, y: 2))
    }

    func testNumeric2DMutatingArithmeticMatchesNonmutatingOperators() {
        var point = CGPoint(x: 1, y: 2)

        point += CGSize(width: 3, height: 4)
        XCTAssertEqual(point, CGPoint(x: 4, y: 6))
        point -= CGVector(dx: 1, dy: 2)
        XCTAssertEqual(point, CGPoint(x: 3, y: 4))
        point.negate()
        XCTAssertEqual(point, CGPoint(x: -3, y: -4))
    }

    func testNumeric2DInterpolationSupportsScalarAndPerAxisParameters() {
        let minimum = CGPoint(x: 0, y: 10)
        let maximum = CGPoint(x: 8, y: 30)

        let scalarResult: CGPoint = lerp(0.25, min: minimum, max: maximum)
        let perAxisResult: CGPoint = lerp(CGPoint(x: 0.25, y: 0.75), min: minimum, max: maximum)
        let inverseResult: CGPoint = ilerp(perAxisResult, min: minimum, max: maximum)

        XCTAssertEqual(scalarResult, CGPoint(x: 2, y: 15))
        XCTAssertEqual(perAxisResult, CGPoint(x: 2, y: 25))
        XCTAssertEqual(inverseResult, CGPoint(x: 0.25, y: 0.75))
    }

    func testNumeric2DClampingCanTargetIndividualAxes() {
        let value = CGPoint(x: -4, y: 12)

        XCTAssertEqual(value.clamped(x: 0...10), CGPoint(x: 0, y: 12))
        XCTAssertEqual(value.clamped(y: 0...10), CGPoint(x: -4, y: 10))
        XCTAssertEqual(value.clamped(to: 0...10), CGPoint(x: 0, y: 10))
    }

    func testGeometryConveniencesPreserveTheirDocumentedMeaning() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)

        XCTAssertEqual(rect.center, CGPoint(x: 25, y: 40))
        XCTAssertEqual(rect.translatedBy(dx: 5, dy: -10), CGRect(x: 15, y: 10, width: 30, height: 40))
        XCTAssertEqual(CGSize(width: 3, height: 4).diagonal, 5, accuracy: 0.000_001)
    }

    func testSizeDiagonalHandlesNegativeAndLargeDimensions() {
        XCTAssertEqual(
            CGSize(width: -3, height: -3).diagonal,
            3 * CGFloat(2).squareRoot(),
            accuracy: 0.000_001
        )

        let large = CGSize(
            width: CGFloat.greatestFiniteMagnitude / 2,
            height: CGFloat.greatestFiniteMagnitude / 3
        )
        XCTAssertTrue(large.diagonal.isFinite)
    }

    func testCoreGraphicsTypesRemainBinaryRepresentable() {
        let scalar = CGFloat(1.25)
        let point = CGPoint(x: 1, y: 2)
        let size = CGSize(width: 3, height: 4)
        let vector = CGVector(dx: 5, dy: 6)
        let rect = CGRect(x: 1, y: 2, width: 4, height: 5)

        XCTAssertEqual(CGFloat(data: scalar.data), scalar)
        XCTAssertEqual(scalar.data, scalar.native.data)
        XCTAssertEqual(scalar.data.count, MemoryLayout<CGFloat.NativeType>.size)
        XCTAssertEqual(CGPoint(data: point.data), point)
        XCTAssertEqual(CGSize(data: size.data), size)
        XCTAssertEqual(CGVector(data: vector.data), vector)
        XCTAssertEqual(CGRect(data: rect.data), rect)
        XCTAssertEqual(rect.data.count, MemoryLayout<CGRect>.size)
        XCTAssertNil(CGRect(validating: Data(count: MemoryLayout<CGRect>.size - 1)))
    }
}
#endif
