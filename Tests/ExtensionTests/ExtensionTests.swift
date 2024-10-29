import XCTest
import SwiftUI
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import MacrosExtension
@testable import SwiftExtension
@testable import FoundationExtension
@testable import CoreGraphicsExtension
@testable import UIKitExtension
@testable import SpriteKitExtension
@testable import SwiftUIExtension
@testable import GeneralExtensions

#if canImport(Macros)
import Macros

let testMacros: [String: Macro.Type] = [
    "FlatEnum": FlatEnumMacro.self,
]
#endif

final class ExtensionTests: XCTestCase
{
    func testBoundingBoxValidity()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        let result1 = r1.union(r2)
        let result2 = union([r1, r2])
        
        XCTAssertEqual(result1, result2)
        
        let result3 = result1.union(r3)
        let result4 = union([r1, r2, r3])
        
        XCTAssertEqual(result3, result4)
    }
    
    func testBoundingBox2Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = r1.union(r2)
        }
    }
    
    func testBoundingBox3Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        
        measure {
            let result1 = r1.union(r2)
            let _ = result1.union(r3)
        }
    }
    
    func testBoundingBoxArray2Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = union([r1, r2])
        }
    }
    
    func testBoundingBoxArray3Performance()
    {
        let r1 = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let r2 = CGRect(origin: CGPoint(x: 300, y: 300), size: CGSize(width: 100, height: 100))
        let r3 = CGRect(origin: CGPoint(x: 1000, y: 200), size: CGSize(width: 100, height: 100))
        
        measure {
            let _ = union([r1, r2, r3])
        }
    }
    
    func testLerpValidity()
    {
        let r1 = CGSize(side: 50)
        let r2 = CGSize(side: 100)
        
        let r3 = lerp(0.5, min: r1, max: r2)
        let r4: CGSize = lerp(0.5, min: r1, max: r2)
        
        XCTAssertEqual(CGSize(side: 75), r3)
        XCTAssertEqual(r4, r3)
    }
    
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
    
    func testMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @FlatEnum
            enum Test {
            case test0(Bool), test1(Int)
            }
            """,
            expandedSource: """
            enum Test {
            case test0(Bool), test1(Int)
            public enum FlatTest {
            case test0
            case test1
            }
            var flat: FlatTest {
                switch self {
                case .test0:
                    return .test0
                case .test1:
                    return .test1
                }
            }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
