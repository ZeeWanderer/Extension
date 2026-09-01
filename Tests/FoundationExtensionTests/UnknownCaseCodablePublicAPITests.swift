//
//  UnknownCaseCodablePublicAPITests.swift
//  Extension
//
//  Created by zeewanderer on 01.09.2026.
//

import Foundation
import FoundationExtension
import XCTest

final class UnknownCaseCodablePublicAPITests: XCTestCase
{
    private enum Status: String, UnknownCaseCodable, Equatable
    {
        case active
        case inactive
        case unknown
    }

    private enum Version: Int, UnknownCaseCodable, Equatable
    {
        case first = 1
        case second = 2
        case unknown = -1
    }

    private enum RenamedFallback: String, UnknownCaseCodable, Equatable
    {
        case current
        case unsupported

        static var unknown: Self { .unsupported }
    }

    private struct Payload: Codable, Equatable
    {
        let status: Status
    }

    func testKnownRawValueDecodesNormally() throws
    {
        let status = try JSONDecoder().decode(
            Status.self,
            from: Data(#""active""#.utf8)
        )

        XCTAssertEqual(status, .active)
    }

    func testUnknownRawValueUsesFallbackCase() throws
    {
        let status = try JSONDecoder().decode(
            Status.self,
            from: Data(#""future-status""#.utf8)
        )

        XCTAssertEqual(status, .unknown)
    }

    func testSynthesizedContainingTypeUsesFallbackCase() throws
    {
        let payload = try JSONDecoder().decode(
            Payload.self,
            from: Data(#"{"status":"future-status"}"#.utf8)
        )

        XCTAssertEqual(payload, Payload(status: .unknown))
    }

    func testFallbackEncodingUsesSentinelRawValue() throws
    {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        let status = try decoder.decode(
            Status.self,
            from: Data(#""future-status""#.utf8)
        )

        XCTAssertEqual(
            try encoder.encode(status),
            Data(#""unknown""#.utf8)
        )
    }

    func testNonStringRawValuesUseTheSameContract() throws
    {
        let decoder = JSONDecoder()

        XCTAssertEqual(
            try decoder.decode(Version.self, from: Data("2".utf8)),
            .second
        )
        XCTAssertEqual(
            try decoder.decode(Version.self, from: Data("99".utf8)),
            .unknown
        )
        XCTAssertEqual(try JSONEncoder().encode(Version.unknown), Data("-1".utf8))
    }

    func testFallbackDoesNotNeedToBeACaseNamedUnknown() throws
    {
        let value = try JSONDecoder().decode(
            RenamedFallback.self,
            from: Data(#""future-value""#.utf8)
        )

        XCTAssertEqual(value, .unsupported)
    }

    func testMalformedRawValueStillThrows() throws
    {
        XCTAssertThrowsError(
            try JSONDecoder().decode(Status.self, from: Data("42".utf8))
        )
        XCTAssertThrowsError(
            try JSONDecoder().decode(Status.self, from: Data("null".utf8))
        )
    }
}
