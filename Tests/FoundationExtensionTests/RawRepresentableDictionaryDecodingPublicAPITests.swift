//
//  RawRepresentableDictionaryDecodingPublicAPITests.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation
import FoundationExtension
import XCTest

final class RawRepresentableDictionaryDecodingPublicAPITests: XCTestCase {
    private enum Key: String, Codable, Sendable {
        case primary
        case secondary
    }

    private struct KeyedModel: Codable, Equatable {
        let values: [Key: Int]
    }

    private final class RecursiveNode: Decodable {
        let value: Int
        let children: [Key: RecursiveNode]
    }

    func testJSONDecoderDecodesATopLevelRawRepresentableKeyedDictionary() throws {
        let data = Data(#"{"primary":1,"secondary":2}"#.utf8)

        let values = try JSONDecoder().decode([Key: Int].self, from: data)

        XCTAssertEqual(values[.primary], 1)
        XCTAssertEqual(values[.secondary], 2)
    }

    func testSynthesizedKeyedDecodingUsesRawRepresentableKeys() throws {
        let data = Data(#"{"values":{"primary":1,"secondary":2}}"#.utf8)

        let model = try JSONDecoder().decode(KeyedModel.self, from: data)

        XCTAssertEqual(model.values[.primary], 1)
        XCTAssertEqual(model.values[.secondary], 2)
    }

    func testRawRepresentableKeyedDictionariesDecodeRecursively() throws {
        let data = Data(
            #"{"primary":{"value":1,"children":{"secondary":{"value":2,"children":{}}}}}"#.utf8
        )

        let roots = try JSONDecoder().decode([Key: RecursiveNode].self, from: data)

        XCTAssertEqual(roots[.primary]?.value, 1)
        XCTAssertEqual(roots[.primary]?.children[.secondary]?.value, 2)
        XCTAssertEqual(roots[.primary]?.children[.secondary]?.children.count, 0)
    }

    func testFoundationEncodedRawRepresentableDictionariesRoundTrip() throws {
        let dictionary: [Key: Int] = [.primary: 1, .secondary: 2]
        let model = KeyedModel(values: dictionary)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let decodedDictionary = try decoder.decode(
            [Key: Int].self,
            from: encoder.encode(dictionary)
        )
        let decodedModel = try decoder.decode(
            KeyedModel.self,
            from: encoder.encode(model)
        )

        XCTAssertEqual(decodedDictionary, dictionary)
        XCTAssertEqual(decodedModel, model)
    }

    func testUnknownRawRepresentableKeyThrowsADataCorruptedError() {
        let data = Data(#"{"unknown":1}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode([Key: Int].self, from: data)) { error in
            guard case DecodingError.dataCorrupted = error else {
                return XCTFail("Expected DecodingError.dataCorrupted, received \(error)")
            }
        }
    }

    func testUnknownNestedRawRepresentableKeyReportsItsFullCodingPath() {
        let data = Data(#"{"values":{"unknown":1}}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(KeyedModel.self, from: data)) { error in
            guard case let DecodingError.dataCorrupted(context) = error else {
                return XCTFail("Expected DecodingError.dataCorrupted, received \(error)")
            }

            XCTAssertEqual(context.codingPath.map(\.stringValue), ["values", "unknown"])
        }
    }

    func testJSONCodingDecodesRawRepresentableKeysAcrossDataAndFileAPIs() async throws {
        let data = Data(#"{"primary":1,"secondary":2}"#.utf8)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Extension-raw-key-dictionary-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try data.write(to: fileURL, options: [.atomic])
        let coding = JSONCoding()
        let expected: [Key: Int] = [.primary: 1, .secondary: 2]

        let synchronousData = try coding.decode([Key: Int].self, from: data)
        let synchronousFile = try coding.decode([Key: Int].self, contentsOf: fileURL)
        let asynchronousData = try await coding.decodeAsync([Key: Int].self, from: data)
        let asynchronousFile = try await coding.decodeAsync(
            [Key: Int].self,
            contentsOf: fileURL
        )
        let detachedData = try await coding.detachedDecodingTask(
            of: [Key: Int].self,
            from: data
        ).value
        let detachedFile = try await coding.detachedDecodingTask(
            of: [Key: Int].self,
            contentsOf: fileURL
        ).value

        XCTAssertEqual(synchronousData, expected)
        XCTAssertEqual(synchronousFile, expected)
        XCTAssertEqual(asynchronousData, expected)
        XCTAssertEqual(asynchronousFile, expected)
        XCTAssertEqual(detachedData, expected)
        XCTAssertEqual(detachedFile, expected)
    }
}
