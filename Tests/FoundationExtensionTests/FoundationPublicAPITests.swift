//
//  FoundationPublicAPITests.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation
import XCTest
import FoundationExtension

final class FoundationPublicAPITests: XCTestCase {
    func testLocalizationDictionaryPrefersRegionThenFallsBackToLanguage() {
        let values: LocalizationDictionary = [
            "en-US": "American English",
            "en": "English",
        ]

        XCTAssertEqual(values[Locale(identifier: "en_US")], "American English")
        XCTAssertEqual(values[Locale(identifier: "en_GB")], "English")
    }

    func testAbsentTypedNumericDefaultIsNil() throws {
        enum Key: String {
            case missing
        }

        let suiteName = "ExtensionTests.MissingDefault.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(defaults.integer(forKey: Key.missing))
        XCTAssertNil(defaults.double(forKey: Key.missing))
        XCTAssertNil(defaults.float(forKey: Key.missing))
    }

    func testPresentTypedNumericDefaultsPreserveStoredValues() throws {
        enum Key: String {
            case integer
            case double
            case float
        }

        let suiteName = "ExtensionTests.PresentDefault.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(42, forKey: Key.integer)
        defaults.set(3.5, forKey: Key.double)
        defaults.set(Float(1.25), forKey: Key.float)

        XCTAssertEqual(defaults.integer(forKey: Key.integer), 42)
        XCTAssertEqual(defaults.double(forKey: Key.double), 3.5)
        XCTAssertEqual(defaults.float(forKey: Key.float), 1.25)
    }
}
