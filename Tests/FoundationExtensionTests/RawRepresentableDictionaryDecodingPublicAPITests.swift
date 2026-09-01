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
    private enum Key: String, Codable {
        case primary
        case secondary
    }

    private struct KeyedModel: Decodable {
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

    func testUnknownRawRepresentableKeyThrowsADataCorruptedError() {
        let data = Data(#"{"unknown":1}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode([Key: Int].self, from: data)) { error in
            guard case DecodingError.dataCorrupted = error else {
                return XCTFail("Expected DecodingError.dataCorrupted, received \(error)")
            }
        }
    }
}
