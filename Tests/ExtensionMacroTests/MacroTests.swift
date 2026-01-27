//
//  MacroTests.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import XCTest

#if canImport(Macros)
import SwiftUI
import SwiftData
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Macros
@testable import MacrosExtension

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

final class MacroTests: XCTestCase
{
#if canImport(Macros)
    nonisolated(unsafe) static let testMacros: [String: Macro.Type] = [
        "FlatEnum": FlatEnumMacro.self,
        "CustomStringConvertibleEnum": CustomStringConvertibleEnumMacro.self,
        "ModelSnapshot": ModelSnapshotMacro.self,
        "ActorProtocol": ActorProtocolMacro.self,
        "ActorProtocolExtension": ActorProtocolExtensionMacro.self,
        "ActorProtocolIgnore": ActorProtocolIgnoreMacro.self,
        "Transactional": TransactionalMacro.self,
        "LogSubsystem": LogSubsystemMacro.self,
        "LogCategory": LogCategoryMacro.self,
    ]
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

                public enum FlatTest: Hashable {
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
            macros: Self.testMacros
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
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testCustomStringConvertibleEnumMacro_FlatEnumMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @CustomStringConvertibleEnum
            @FlatEnum
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP
            }
            """,
            expandedSource: """
            enum Test: Hashable {
                case test0(Bool)
                case test1 // TMP

                public enum FlatTest: Hashable {
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
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testModelSnapshotMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
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
            """,
            expandedSource: """
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
                    public init(from model: Test1) {
                        self.persistentModelID = model.persistentModelID
                        self.int = model.int
                    }
                }

                public struct ShallowSnapshot: SnapshotProtocol, Sendable {
                    public let persistentModelID: PersistentIdentifier
                    public let int: Int
                    public init(from model: Test1) {
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
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testActorProtocolMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            import SwiftUI
            import SwiftData

            @ActorProtocol
            public protocol DataService: Sendable {
                var context: Int { get }
                func getContext0() -> Int
                func getContext1() -> Int
            }
            
            @ActorProtocolExtension(name: "DataService")
            struct DataServiceImpl: DataService {
                var context: Int { 0 }
                override public func getContext0() -> Int { context }
                @ActorProtocolIgnore
                override public func getContext1() -> Int { context }
            }
            """,
            expandedSource: """
            import SwiftUI
            import SwiftData
            public protocol DataService: Sendable {
                var context: Int { get }
                func getContext0() -> Int
                func getContext1() -> Int
            }

            public protocol DataServiceActor: Sendable, Actor {
                var context: Int {
                    get
                }
                func getContext0() async -> Int
                func getContext1() async -> Int
            }
            struct DataServiceImpl: DataService {
                var context: Int { 0 }
                override public func getContext0() -> Int { context }
                override public func getContext1() -> Int { context }
            }

            extension DataService {
                func getContext0() -> Int {
                    context
                }
                func getContext1() -> Int {
                    context
                }
            }

            extension DataServiceActor {
                func getContext0() -> Int {
                    context
                }
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTransactionalMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            import SwiftUI
            import SwiftData

            class Test {
                let modelContext: ModelContext
            
                @Transactional(retval: 0)
                func test0(_ int: Int) -> Int 
                {
                    let newInt = 7 + int
                    return newInt
                }
            
                @Transactional
                func test1(_ int: Int)
                {
                    let newInt = 7 + int
                }
            
                @Transactional
                func test2(_ ctx: ModelContext, _ int: Int)
                {
                    let newInt = 7 + int
                }
            
                @Transactional
                public static func test3(_ ctx: ModelContext, _ int: Int)
                {
                    let newInt = 7 + int
                }
            
                @Transactional
                public static func test4(_ ctx: ModelContext?, _ int: Int)
                {
                    let newInt = 7 + int
                }
            
                @Transactional(retval: 0)
                public static func test5(_ ctx: ModelContext?, _ int: Int) -> Int
                {
                    let newInt = 7 + int
                    return newInt
                }
            
                @Transactional(keyPath: \\.modelContext?, retval: 0)
                public static func test6(_ int: Int) -> Int
                {
                    let newInt = 7 + int
                    return newInt
                }
            
                @Transactional(keyPath: \\.modelContext?, retval: 0)
                public static func test7(_ ctx: ModelContext?, _ int: Int) -> Int
                {
                    let newInt = 7 + int
                    return newInt
                }
            
                @Transactional(keyPath: \\.modelContext?, retval: 0)
                public static func test8(_ ctx: ModelContext?, _ int: Int) -> Int
                {
                    let newInt = 7 + int
                    return newInt
                }
            }
            """,
            expandedSource: """
            import SwiftUI
            import SwiftData

            class Test {
                let modelContext: ModelContext
                func test0(_ int: Int) -> Int {
                    func __original_test0(_ int: Int) -> Int
                        {
                            let newInt = 7 + int
                            return newInt
                        }
                    if TransactionContext.isActive {
                        return __original_test0(int)
                    } else {
                        return TransactionContext.$isActive.withValue(true) {
                            var retval: Int = 0
                            try? modelContext.transaction() {
                                retval = __original_test0(int)
                            }
                            return retval
                        }
                    }
                }
                func test1(_ int: Int){
                    func __original_test1(_ int: Int)
                        {
                            let newInt = 7 + int
                        }
                    if TransactionContext.isActive {
                        __original_test1(int)
                    } else {
                        TransactionContext.$isActive.withValue(true) {
                            try? modelContext.transaction() {
                                __original_test1(int)
                            }
                        }
                    }
                }
                func test2(_ ctx: ModelContext, _ int: Int){
                    func __original_test2(_ ctx: ModelContext, _ int: Int)
                        {
                            let newInt = 7 + int
                        }
                    if TransactionContext.isActive {
                        __original_test2(ctx, int)
                    } else {
                        TransactionContext.$isActive.withValue(true) {
                            try? ctx.transaction() {
                                __original_test2(ctx, int)
                            }
                        }
                    }
                }
                public static func test3(_ ctx: ModelContext, _ int: Int){
                    func __original_test3(_ ctx: ModelContext, _ int: Int)
                        {
                            let newInt = 7 + int
                        }
                    if TransactionContext.isActive {
                        __original_test3(ctx, int)
                    } else {
                        TransactionContext.$isActive.withValue(true) {
                            try? ctx.transaction() {
                                __original_test3(ctx, int)
                            }
                        }
                    }
                }
                public static func test4(_ ctx: ModelContext?, _ int: Int){
                    func __original_test4(_ ctx: ModelContext?, _ int: Int)
                        {
                            let newInt = 7 + int
                        }
                    if let context = ctx {
                        if TransactionContext.isActive {
                            __original_test4(ctx, int)
                        } else {
                            TransactionContext.$isActive.withValue(true) {
                                try? context.transaction() {
                                    __original_test4(ctx, int)
                                }
                            }
                        }
                    } else {
                        __original_test4(ctx, int)
                    }
                }
                public static func test5(_ ctx: ModelContext?, _ int: Int) -> Int{
                    func __original_test5(_ ctx: ModelContext?, _ int: Int) -> Int
                        {
                            let newInt = 7 + int
                            return newInt
                        }
                    if let context = ctx {
                        if TransactionContext.isActive {
                            return __original_test5(ctx, int)
                        } else {
                            return TransactionContext.$isActive.withValue(true) {
                                var retval: Int = 0
                                try? context.transaction() {
                                    retval = __original_test5(ctx, int)
                                }
                                return retval
                            }
                        }
                    } else {
                        return __original_test5(ctx, int)
                    }
                }
                public static func test6(_ int: Int) -> Int{
                    func __original_test6(_ int: Int) -> Int
                        {
                            let newInt = 7 + int
                            return newInt
                        }
                    if let context = self[keyPath: \\.modelContext?] {
                        if TransactionContext.isActive {
                            return __original_test6(int)
                        } else {
                            return TransactionContext.$isActive.withValue(true) {
                                var retval: Int = 0
                                try? context.transaction() {
                                    retval = __original_test6(int)
                                }
                                return retval
                            }
                        }
                    } else {
                        return __original_test6(int)
                    }
                }
                public static func test7(_ ctx: ModelContext?, _ int: Int) -> Int{
                    func __original_test7(_ ctx: ModelContext?, _ int: Int) -> Int
                        {
                            let newInt = 7 + int
                            return newInt
                        }
                    if let context = self[keyPath: \\.modelContext?] {
                        if TransactionContext.isActive {
                            return __original_test7(ctx, int)
                        } else {
                            return TransactionContext.$isActive.withValue(true) {
                                var retval: Int = 0
                                try? context.transaction() {
                                    retval = __original_test7(ctx, int)
                                }
                                return retval
                            }
                        }
                    } else {
                        return __original_test7(ctx, int)
                    }
                }
                public static func test8(_ ctx: ModelContext?, _ int: Int) -> Int{
                    func __original_test8(_ ctx: ModelContext?, _ int: Int) -> Int
                        {
                            let newInt = 7 + int
                            return newInt
                        }
                    if let context = self[keyPath: \\.modelContext?] {
                        if TransactionContext.isActive {
                            return __original_test8(ctx, int)
                        } else {
                            return TransactionContext.$isActive.withValue(true) {
                                var retval: Int = 0
                                try? context.transaction() {
                                    retval = __original_test8(ctx, int)
                                }
                                return retval
                            }
                        }
                    } else {
                        return __original_test8(ctx, int)
                    }
                }
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLogSubsystemMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @LogSubsystem
            enum AppLog {}
            """,
            expandedSource: """
            enum AppLog {}

            extension AppLog: LogSubsystemProtocol {
                nonisolated static let logger = makeLogger()
                nonisolated static let signposter = makeSignposter()
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLogCategoryMacro() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @LogCategory(subsystem: AppLog.self)
            struct NetworkLog {}
            """,
            expandedSource: """
            struct NetworkLog {}

            extension NetworkLog: LogSubsystemCategoryProtocol {
                typealias Subsystem = AppLog
                nonisolated static let logger = makeLogger()
                nonisolated static let signposter = makeSignposter()
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLogSubsystemMacro_Private() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @LogSubsystem
            private enum UIImageViewLog {}
            """,
            expandedSource: """
            private enum UIImageViewLog {}

            extension UIImageViewLog: LogSubsystemProtocol {
                nonisolated static let logger = makeLogger()
                nonisolated static let signposter = makeSignposter()
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testLogCategoryMacro_Private() throws {
        #if canImport(Macros)
        assertMacroExpansion(
            """
            @LogCategory(subsystem: Media.self)
            private enum UIImageViewLog {}
            """,
            expandedSource: """
            private enum UIImageViewLog {}

            extension UIImageViewLog: LogSubsystemCategoryProtocol {
                typealias Subsystem = Media
                nonisolated static let logger = makeLogger()
                nonisolated static let signposter = makeSignposter()
            }
            """,
            macros: Self.testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
#endif
