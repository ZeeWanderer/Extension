//
//  SwiftUIExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation
import XCTest
import SwiftUI
import SwiftUIExtension

#if canImport(SwiftUI)
final class SwiftUIColorPublicAPITests: XCTestCase {
    func testHexInitializersAcceptDocumentedPrefixesAndAlphaForms() {
        let expected = Color(hex: 0xFF00FF, opacity: 0)
        let variants = [
            Color(hex: "FF00FF00"),
            Color(hex: "FF00FF", opacity: 0),
            Color(hex: "#FF00FF00"),
            Color(hex: "0xFF00FF00"),
            Color(hex: "0XFF00FF00"),
            Color(hex: "0XFF00FFFF", opacity: 0),
        ]

        for variant in variants {
            XCTAssertEqual(variant, expected)
        }
    }

    func testCyclicScheduleHandlesValidAndEmptyOffsets() {
        var entries = CyclicTimelineSchedule.Entries(
            last: Date(timeIntervalSinceReferenceDate: 0),
            offsets: [1, 2]
        )
        XCTAssertEqual(entries.next(), Date(timeIntervalSinceReferenceDate: 1))
        XCTAssertEqual(entries.next(), Date(timeIntervalSinceReferenceDate: 3))
        XCTAssertEqual(entries.next(), Date(timeIntervalSinceReferenceDate: 4))

        var empty = CyclicTimelineSchedule.Entries(last: .now, offsets: [])
        XCTAssertNil(empty.next())
    }

    func testCenterAnchoredResizeVariantsKeepTheOriginalCenter() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let resized = [
            rect.scaled(by: 2),
            rect.scaleResize(x: 2, y: 0.5),
            rect.scaleResize(x: 2),
            rect.scaleResize(y: 0.5),
            rect.resize(width: 200, height: 40),
            rect.resize(width: 200),
            rect.resize(height: 40),
        ]

        for value in resized {
            XCTAssertEqual(value.midX, rect.midX, accuracy: 0.000_001)
            XCTAssertEqual(value.midY, rect.midY, accuracy: 0.000_001)
        }
    }

    func testEveryStandardAnchorRemainsFixedAcrossScalingAndResizing() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let anchors: [UnitPoint] = [
            .topLeading, .top, .topTrailing,
            .leading, .center, .trailing,
            .bottomLeading, .bottom, .bottomTrailing,
        ]

        for anchor in anchors {
            let expected = anchoredPoint(of: rect, at: anchor)
            let results = [
                rect.scaled(by: 1.75, anchor: anchor),
                rect.scaleResize(x: 1.5, y: 0.25, anchor: anchor),
                rect.resize(width: 37, height: 211, anchor: anchor),
            ]

            for result in results {
                let actual = anchoredPoint(of: result, at: anchor)
                XCTAssertEqual(actual.x, expected.x, accuracy: 0.000_001)
                XCTAssertEqual(actual.y, expected.y, accuracy: 0.000_001)
            }
        }
    }

    func testEveryResizeVariantPreservesATopLeadingAnchor() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 80)
        let expectedOrigin = rect.origin
        let results = [
            rect.scaled(by: 2, anchor: .topLeading),
            rect.scaleResize(x: 2, y: 0.5, anchor: .topLeading),
            rect.scaleResize(x: 2, anchor: .topLeading),
            rect.scaleResize(y: 0.5, anchor: .topLeading),
            rect.resize(width: 200, height: 40, anchor: .topLeading),
            rect.resize(width: 200, anchor: .topLeading),
            rect.resize(height: 40, anchor: .topLeading),
        ]

        for result in results {
            XCTAssertEqual(result.origin, expectedOrigin)
        }
    }

    private func anchoredPoint(of rect: CGRect, at anchor: UnitPoint) -> CGPoint {
        CGPoint(
            x: rect.minX + anchor.x * rect.width,
            y: rect.minY + anchor.y * rect.height
        )
    }
}
#endif
