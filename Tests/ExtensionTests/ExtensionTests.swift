import XCTest
import SwiftUI
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftData
@testable import MacrosExtension
@testable import SwiftExtension
@testable import FoundationExtension
@testable import osExtension
@testable import ObservationExtension
@testable import AccelerateExtension
@testable import CoreGraphicsExtension
@testable import UIKitExtension
@testable import SpriteKitExtension
@testable import SwiftUIExtension
@testable import GeneralExtensions

#if canImport(Macros)
import Macros

let testMacros: [String: Macro.Type] = [
    "FlatEnum": FlatEnumMacro.self,
    "CustomStringConvertibleEnum": CustomStringConvertibleEnumMacro.self,
    "ModelSnapshot": ModelSnapshotMacro.self
]
#endif

@ModelSnapshot
@Model
class Test1 {
    var int: Int = 0

    @SnapshotIgnore
    @Relationship
    var test0: Test0? = nil
    
    init(int: Int, test0: Test0? = nil) {
        self.int = int
        self.test0 = test0
    }
}

@ModelSnapshot
@Model
class Test0 {
    var int: Int = 0

    @Relationship
    var tests: [Test1] = []
    
    init(int: Int, tests: [Test1]) {
        self.int = int
        self.tests = tests
    }
}

final class ExtensionTests: XCTestCase
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
        let r1 = Array<Int>([0, 1, 2, 3])
        let r1d = r1.data
        let r1c = Array<Int>(data: r1d)
        
        struct Test0: Equatable, SafeBinaryRepresentable
        {
            let int0: Int
            let int1: Int
        }
        
        let t0: Test0 = .init(int0: 0, int1: 1)
        let t0r: Data = t0.data
        let t0r1 = Test0(data: t0r)
        
        let t1: CGRect = .init(x: 1, y: 2, width: 4, height: 5)
        let t1r: Data = t1.data
        let t1r1 = CGRect(data: t1r)
        
        let t2: [Double] = [1, 2, 4, 5]
        let t2r: Data = t2.data
        let t2r1 = CGRect(data: t2r)
        
        let t3: [Double] = [1, 2, 4]
        let t3r: Data = t3.data
        let t3r1 = CGRect(validating: t3r)
        
        let r2 = Array<Test0>([.init(int0: 0, int1: 1), .init(int0: 2, int1: 3)])
        let r2d = r2.data
        let r2c = Array<Test0>(data: r2d)
        
        let r3 = Set<Int>([1,2,3])
        let r3d = r3.data
        let r3c = Set<Int>(data: r3d)
        
        XCTAssertEqual(r1, r1c)
        XCTAssertEqual(r2, r2c)
        XCTAssertEqual(r3, r3c)
        XCTAssertEqual(t0, t0r1)
        XCTAssertEqual(t1, t1r1)
        XCTAssertEqual(t1, t2r1)
        XCTAssertEqual(nil, t3r1)
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
    
    @ModelSnapshot
    @Model
    class Test1 {
        var int: Int = 0
        var intArray: [Int] = []

        @SnapshotIgnore
        @Relationship
        var test0: Test0? = nil
        
        init(int: Int, test0: Test0? = nil) {
            self.int = int
            self.test0 = test0
            self.intArray = []
        }
    }

    @ModelSnapshot
    @Model
    class Test0 {
        var int: Int = 0

        @Relationship
        var tests: [Test1] = []
        
        init(int: Int, tests: [Test1]) {
            self.int = int
            self.tests = tests
        }
    }
    
    func testModelSnapshotMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            import SwiftData
            
            @ModelSnapshot
            @Model
            class Test1 {
                var int: Int = 0
                var intArray: [Int] = []
                
                @SnapshotIgnore
                @Relationship
                var test0: Test0? = nil
                
                init(int: Int, test0: Test0? = nil) {
                    self.int = int
                    self.test0 = test0
                    self.intArray = []
                }
            }
            
            @ModelSnapshot
            @Model
            class Test0 {
                var int: Int = 0
                
                @Relationship
                var tests: [Test1] = []
                
                init(int: Int, tests: [Test1]) {
                    self.int = int
                    self.tests = tests
                }
            }
            """,
            expandedSource: """
            import SwiftData
            @Model
            class Test1 {
                var int: Int = 0
                var intArray: [Int] = []
                
                @SnapshotIgnore
                @Relationship
                var test0: Test0? = nil
                
                init(int: Int, test0: Test0? = nil) {
                    self.int = int
                    self.test0 = test0
                    self.intArray = []
                }

                /// A protocol to streamline usage of ``Snapshot`` and ``ShallowSnapshot``
                public protocol SnapshotProtocol: Sendable {
                    var persistentModelID: PersistentIdentifier {
                        get
                    }
                    var int: Int {
                        get
                    }
                    var intArray: [Int] {
                        get
                    }
                }

                public struct Snapshot: SnapshotProtocol, Sendable {
                    public let persistentModelID: PersistentIdentifier
                    public let int: Int
                    public let intArray: [Int]
                    public init(from model: Test1) {
                        self.persistentModelID = model.persistentModelID
                        self.int = model.int
                        self.intArray = model.intArray
                    }
                }

                public struct ShallowSnapshot: SnapshotProtocol, Sendable {
                    public let persistentModelID: PersistentIdentifier
                    public let int: Int
                    public let intArray: [Int]
                    public init(from model: Test1) {
                        self.persistentModelID = model.persistentModelID
                        self.int = model.int
                        self.intArray = model.intArray
                    }
                }

                /// - Important: This version snapshots all the relationships that are not not marked by `SnapshotIgnore`
                /// If you need just the snapshot of the current object use ``shallowSnapshot`` instead
                public var snapshot: Snapshot {
                    return Snapshot(from: self)
                }
                public var shallowSnapshot: ShallowSnapshot {
                    return ShallowSnapshot(from: self)
                }
            }
            @Model
            class Test0 {
                var int: Int = 0
                
                @Relationship
                var tests: [Test1] = []
                
                init(int: Int, tests: [Test1]) {
                    self.int = int
                    self.tests = tests
                }

                /// A protocol to streamline usage of ``Snapshot`` and ``ShallowSnapshot``
                public protocol SnapshotProtocol: Sendable {
                    var persistentModelID: PersistentIdentifier {
                        get
                    }
                    var int: Int {
                        get
                    }
                }

                public struct Snapshot: SnapshotProtocol, Sendable {
                    public let persistentModelID: PersistentIdentifier
                    public let int: Int
                    public let tests: [Test1.Snapshot]
                    public init(from model: Test0) {
                        self.persistentModelID = model.persistentModelID
                        self.int = model.int
                        self.tests = model.tests.map { Test1.Snapshot(from: $0) }
                    }
                }

                public struct ShallowSnapshot: SnapshotProtocol, Sendable {
                    public let persistentModelID: PersistentIdentifier
                    public let int: Int
                    public init(from model: Test0) {
                        self.persistentModelID = model.persistentModelID
                        self.int = model.int
                    }
                }

                /// - Important: This version snapshots all the relationships that are not not marked by `SnapshotIgnore`
                /// If you need just the snapshot of the current object use ``shallowSnapshot`` instead
                public var snapshot: Snapshot {
                    return Snapshot(from: self)
                }
                public var shallowSnapshot: ShallowSnapshot {
                    return ShallowSnapshot(from: self)
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
