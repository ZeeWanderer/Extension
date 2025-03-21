import XCTest
import SwiftUI
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import MacrosExtension
#if canImport(UIKit)
@testable import SwiftExtension
@testable import FoundationExtension
@testable import CoreGraphicsExtension
@testable import UIKitExtension
@testable import SpriteKitExtension
@testable import SwiftUIExtension
@testable import GeneralExtensions
#endif

#if canImport(Macros)
import Macros

let testMacros: [String: Macro.Type] = [
    "FlatEnum": FlatEnumMacro.self,
    "CustomStringConvertibleEnum": CustomStringConvertibleEnumMacro.self
]
#endif

final class ExtensionTests: XCTestCase
{
    
#if canImport(UIKit)
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
    
    func testBinaryRepresentable()
    {
        let r1 = Set([0, 1, 2, 3])
        let r1d = r1.data
        let r1c = Set<Int>(data: r1d)
        
        struct Test0: Hashable
        {
            let int0: Int
            let int1: Int
        }
        
        let r2 = Set<Test0>([.init(int0: 0, int1: 1), .init(int0: 2, int1: 3)])
        let r2d = r2.data
        let r2c = Set<Test0>(data: r2d)
        
        XCTAssertEqual(r1, r1c)
        XCTAssertEqual(r2, r2c)
    }
#endif
    
    func testFlatEnumMacro() throws {
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

                public var flat: FlatTest {
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
    
    func testCustomStringConvertibleEnumMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @CustomStringConvertibleEnum
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP
            }
            """,
            expandedSource: """
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP
            }

            extension Test: CustomStringConvertible, CustomDebugStringConvertible {
                public var description: String {
                    switch self {
                    case .test0(let value0):
                        return "test0(\\(value0))"
                    case .test1:
                        return "test1"
                    }
                }
                public var debugDescription: String {
                    switch self {
                    case .test0(let value0):
                        return "test0(\\(value0))"
                    case .test1:
                        return "test1"
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
    
    func testCustomStringConvertibleEnumMacro_FlatEnumMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @FlatEnum @CustomStringConvertibleEnum
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP
            }
            """,
            expandedSource: """
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP

                public enum FlatTest {
                    case test0
                    case test1
                }

                public var flat: FlatTest {
                    switch self {
                    case .test0:
                        return .test0
                    case .test1:
                        return .test1
                    }
                }
            }

            extension FlatTest: CustomStringConvertible, CustomDebugStringConvertible {
                public var description: String {
                    switch self {
                    case .test0:
                        return "test0"
                    case .test1:
                        return "test1"
                    }
                }
                public var debugDescription: String {
                    switch self {
                    case .test0:
                        return "test0"
                    case .test1:
                        return "test1"
                    }
                }
            }

            extension Test: CustomStringConvertible, CustomDebugStringConvertible {
                public var description: String {
                    switch self {
                    case .test0(let value0):
                        return "test0(\\(value0))"
                    case .test1:
                        return "test1"
                    }
                }
                public var debugDescription: String {
                    switch self {
                    case .test0(let value0):
                        return "test0(\\(value0))"
                    case .test1:
                        return "test1"
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
