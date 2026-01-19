//
//  UserDefaultsObservableTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest
@testable import FoundationExtension
@testable import ObservationExtension

final class UserDefaultsObservableTests: XCTestCase
{
    @available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
    @Observable
    final class Testobservable: UserDefaultsObservable
    {
        struct Test: SafeBinaryRepresentable, Equatable
        {
            let int: Int
        }
        
        enum UserDefaultsKey: String, CodingKey
        {
            case name
            case array
        }
        
        var array: [Test]
        {
            get {
                userDefaultsGet(.name) ?? []
            }
            set {
                userDefaultsSet(.name, newValue: newValue)
            }
        }
    }
    
    @available(iOS 17.0, macCatalyst 17.0, macOS 14.0, *)
    func testUserDefaultsObservable()
    {
        let array_ : [Testobservable.Test] = [.init(int: 0), .init(int: 25)]
        let test = Testobservable()
        test.array = array_
        let arrayR = test.array
        XCTAssertEqual(arrayR, array_)
    }
}
