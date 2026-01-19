//
//  UIKitExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest
@testable import FoundationExtension
@testable import UIKitExtension

#if canImport(UIKit)
final class UIKitExtensionTests: XCTestCase
{
    func testHEXStringToUIColor()
    {
        let r0 = UIColor(hex: 0xFF00FF, alpha: 0)
        let r1 = UIColor(hex: "FF00FF00")
        let r2 = UIColor(hex: "FF00FF", alpha: 0)
        let r3 = UIColor(hex: "#FF00FF00")
        let r4 = UIColor(hex: "0xFF00FF00")
        let r5 = UIColor(hex: "0XFF00FF00")
        let r6 = UIColor(hex: "0XFF00FFFF", alpha: 0)
        
        XCTAssertEqual(r0, r1)
        XCTAssertEqual(r0, r2)
        XCTAssertEqual(r0, r3)
        XCTAssertEqual(r0, r4)
        XCTAssertEqual(r0, r5)
        XCTAssertEqual(r0, r6)
    }
}
#endif
