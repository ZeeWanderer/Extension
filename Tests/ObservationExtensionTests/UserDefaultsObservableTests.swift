//
//  UserDefaultsObservableTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation
import XCTest
import FoundationExtension
import ObservationExtension

final class UserDefaultsObservablePublicAPITests: XCTestCase {
    @available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
    @Observable final class TestObservable: UserDefaultsObservable {
        struct TestValue: SafeBinaryRepresentable, Equatable {
            let int: Int
        }

        enum TestMode: String {
            case enabled
        }

        enum UserDefaultsKey: String, CodingKey {
            case array
            case mode
        }
    }

    @available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
    func testBinaryRepresentableValuesRoundTripInAnIsolatedSuite() throws {
        let suiteName = "ExtensionTests.UserDefaultsObservable.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let observable = TestObservable()
        let expected: [TestObservable.TestValue] = [.init(int: 0), .init(int: 25)]

        XCTAssertTrue(observable.userDefaultsSet(.array, defaults, newValue: expected))
        let decoded: [TestObservable.TestValue]? = observable.userDefaultsGet(.array, defaults)

        XCTAssertEqual(decoded, expected)
    }

    @available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
    func testRawRepresentableValuesUseTheirPublicRawValue() throws {
        let suiteName = "ExtensionTests.UserDefaultsObservable.Raw.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let observable = TestObservable()

        XCTAssertTrue(observable.userDefaultsSet(.mode, defaults, newValue: TestObservable.TestMode.enabled))
        let decoded: TestObservable.TestMode? = observable.userDefaultsGet(.mode, defaults)

        XCTAssertEqual(defaults.string(forKey: TestObservable.UserDefaultsKey.mode), "enabled")
        XCTAssertEqual(decoded, .enabled)
    }

    func testReadsExistingPropertyListRawJSONAndBinaryPreferences() throws {
        let suiteName = "ExtensionTests.UserDefaultsObservable.Upgrade.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let observable = TestObservable()

        // Seed the underlying defaults as a previous installation would leave them.
        defaults.set([7, 42], forKey: "array")
        let plist: [UInt32]? = observable.userDefaultsGet(.array, defaults)
        XCTAssertEqual(plist, [7, 42])

        defaults.set("[7,42]", forKey: "array")
        let json: Set<UInt32>? = observable.userDefaultsGet(.array, defaults)
        XCTAssertEqual(json, [7, 42])

        defaults.set(Data([7, 0, 0, 0, 42, 0, 0, 0]), forKey: "array")
        let binary: Set<UInt32>? = observable.userDefaultsGet(.array, defaults)
        XCTAssertEqual(binary, [7, 42])
    }
}
