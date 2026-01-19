//
//  SwiftUIExtensionTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest
import SwiftUI
@testable import SwiftUIExtension

#if canImport(SwiftUI)
final class SwiftUIExtensionTests: XCTestCase
{
    func testHEXStringToColor()
    {
        let r0 = Color(hex: 0xFF00FF, opacity: 0)
        let r1 = Color(hex: "FF00FF00")
        let r2 = Color(hex: "FF00FF", opacity: 0)
        let r3 = Color(hex: "#FF00FF00")
        let r4 = Color(hex: "0xFF00FF00")
        let r5 = Color(hex: "0XFF00FF00")
        let r6 = Color(hex: "0XFF00FFFF", opacity: 0)
        
        XCTAssertEqual(r0, r1)
        XCTAssertEqual(r0, r2)
        XCTAssertEqual(r0, r3)
        XCTAssertEqual(r0, r4)
        XCTAssertEqual(r0, r5)
        XCTAssertEqual(r0, r6)
    }
}
#endif
