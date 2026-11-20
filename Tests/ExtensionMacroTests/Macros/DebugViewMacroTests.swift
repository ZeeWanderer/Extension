//
//  DebugViewMacroTests.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

import XCTest

#if os(macOS) && canImport(Macros)
import Macros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import SwiftIfConfig
import SwiftBasicFormat

final class DebugViewMacroTests: XCTestCase
{
    func testOrdinaryFunctionExpansionPreservesConcreteTypesAndAddsReturn()
    {
        assertMacroExpansion(
            """
            @debug_view
            func content() -> some View {
                Text(.sample).font(.headline).padding()
            }
            """,
            expandedSource: """
            func content() -> some View {
                let __macro_local_12p_debug_viewfMu_ = Text(.sample)
                let __macro_local_12p_debug_viewfMu0_ = __macro_local_12p_debug_viewfMu_.font(.headline)
                let __macro_local_12p_debug_viewfMu1_ = __macro_local_12p_debug_viewfMu0_.padding()
                return __macro_local_12p_debug_viewfMu1_
            }
            """,
            diagnostics: [Self.p_reminder],
            macros: ["debug_view": DebugViewMacro.self],
            buildConfiguration: Self.p_configuration(debug: true)
        )
    }

    func testExplicitBuilderExpansionRetainsBuilderSemanticsInAnIndependentScope()
    {
        assertMacroExpansion(
            """
            @debug_view
            @ViewBuilder
            var body: some View {
                Text("Hello").padding()
            }
            """,
            expandedSource: """
            @ViewBuilder
            var body: some View {
                @ViewBuilder func __macro_local_17p_debug_view_bodyfMu_() -> some View {
                    let __macro_local_12p_debug_viewfMu_ = Text("Hello")
                    let __macro_local_12p_debug_viewfMu0_ = __macro_local_12p_debug_viewfMu_.padding()
                    __macro_local_12p_debug_viewfMu0_
                }
                return __macro_local_17p_debug_view_bodyfMu_()
            }
            """,
            diagnostics: [Self.p_reminder],
            macros: ["debug_view": DebugViewMacro.self],
            buildConfiguration: Self.p_configuration(debug: true)
        )
    }

    func testReleaseExpansionIsUnmodifiedButStillWarns()
    {
        assertMacroExpansion(
            """
            @debug_view
            @ViewBuilder
            var body: some View {
                Text(.sample).font(.headline).padding()
            }
            """,
            expandedSource: """
            @ViewBuilder
            var body: some View {
                Text(.sample).font(.headline).padding()
            }
            """,
            diagnostics: [Self.p_reminder],
            macros: ["debug_view": DebugViewMacro.self],
            buildConfiguration: Self.p_configuration(debug: false)
        )
    }

    func testUnknownBuildConfigurationDoesNotRiskRewritingReleaseCode() throws
    {
        let function = try FunctionDeclSyntax("func content() -> Text { Text(\"Hi\").bold() }")
        let context = BasicMacroExpansionContext()
        let result = try DebugViewMacro.expansion(of: "@debug_view", providingBodyFor: function, in: context)
        XCTAssertTrue(result.isEmpty, "No replacement body must be emitted when the client configuration is unknown.")
        XCTAssertEqual(context.diagnostics.count, 2)
        XCTAssertTrue(context.diagnostics.last?.message.contains("original body is unchanged") == true)
    }

    func testBothAttributeOrdersOnFunctionsPreserveViewBuilder() throws
    {
        for attributes in ["@debug_view @ViewBuilder", "@ViewBuilder @debug_view", "@debug_view @SwiftUI.ViewBuilder"] {
            let result = try p_expand("\(attributes) func content() -> some View { Text(\"a\").padding() }")
            XCTAssertTrue(result.contains("let __macro_local_"))
            XCTAssertTrue(result.contains("@ViewBuilder"))
            XCTAssertEqual(result.components(separatedBy: "return ").count - 1, 1)
        }
    }

    func testRethrowingBuilderKeepsItsOriginalEffectContract() throws
    {
        let function = try FunctionDeclSyntax("@ViewBuilder func content(_ make: () throws -> Text) rethrows -> some View { try make(); Text(\"Hi\").padding() }")
        let context = BasicMacroExpansionContext(buildConfiguration: Self.p_configuration(debug: true))
        let result = try DebugViewMacro.expansion(of: "@debug_view", providingBodyFor: function, in: context)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(context.diagnostics.count, 2)
        XCTAssertTrue(context.diagnostics.last?.message.contains("leaves rethrows builder helpers unchanged") == true)
    }

    func testBuilderBranchesAvailabilityAndConditionalCompilationAreRewritten() throws
    {
        let result = try p_expand("""
        @ViewBuilder func content() -> some View {
            if #available(macOS 99, *) {
                Text("future").padding().border(.red)
            } else if flag {
                Text("flag").padding().border(.red)
            } else {
                Text("fallback").padding().border(.red)
            }
            switch number {
            case 1: Text("one").padding().border(.red)
            default: Text("other").padding().border(.red)
            }
            #if FEATURE
            Text("feature").padding().border(.red)
            #else
            Text("normal").padding().border(.red)
            #endif
        }
        """)
        XCTAssertEqual(result.components(separatedBy: "let __macro_local_").count - 1, 21)
        XCTAssertTrue(result.contains("#available(macOS 99, *)"))
        XCTAssertTrue(result.contains("#if FEATURE"))
        XCTAssertEqual(result.components(separatedBy: "return ").count - 1, 1)
    }

    func testActionAndUnknownClosuresAreNotRewritten() throws
    {
        let result = try p_expand("""
        @ViewBuilder func content() -> some View {
            VStack {
                Text("a").onTapGesture { service.first().second() }
                    .task { await service.first().second() }
                Button { service.first().second() } label: { Text("label").padding() }
                Button(action: { service.first().second() }) { Text("other").padding() }
                Button(action: { service.first().second() }, label: { Text("explicit").padding() })
                CustomContainer { Text("custom").padding() }
            }
        }
        """)
        XCTAssertEqual(result.components(separatedBy: "service.first().second()").count - 1, 5)
        XCTAssertTrue(result.contains("Text(\"custom\").padding()"))
        XCTAssertFalse(result.contains("Text(\"label\").padding()"))
        XCTAssertFalse(result.contains("Text(\"other\").padding()"))
        XCTAssertFalse(result.contains("Text(\"explicit\").padding()"))
    }

    func testOptionalLeadingDotTryAndAwaitChainsStayIntact() throws
    {
        for expression in [
            "optional?.padding().border(.red)",
            ".init(\"a\").font(.headline)",
            "try source.make().modify()",
            "await source.make().modify()",
        ] {
            let result = try p_expand("func content() -> some View { \(expression) }")
            XCTAssertFalse(result.contains("p_debug_view"), expression)
            XCTAssertTrue(result.contains(expression), expression)
        }
    }

    func testAmbiguousControlAndPresentationActionsStayIntact() throws
    {
        let result = try p_expand("""
        @ViewBuilder func content() -> some View {
            Slider(value: $value) { _ in service.first().second() }
            Menu(content: { Text("item").padding() }, label: { Text("menu").bold() }) { service.first().second() }
            Text("Sheet").sheet(isPresented: $shown) { service.first().second() } content: { Text("sheet").padding() }
            Text("Cover").fullScreenCover(isPresented: $shown) { service.first().second() } content: { Text("cover").padding() }
        }
        """)
        XCTAssertEqual(result.components(separatedBy: "service.first().second()").count - 1, 4)
        XCTAssertFalse(result.contains("Text(\"sheet\").padding()"))
        XCTAssertFalse(result.contains("Text(\"cover\").padding()"))
        XCTAssertFalse(result.contains("Text(\"item\").padding()"))
    }

    func testPlainIfExpressionDoesNotAcquireMultipleStatementBranches() throws
    {
        let result = try p_expand("""
        func content() -> Text {
            if flag { Text("a").bold() } else { Text("b").bold() }
        }
        """)
        XCTAssertFalse(result.contains("p_debug_view"))
    }

    func testArgumentsAreNotHoistedAndNamesCannotCollide() throws
    {
        let result = try p_expand("""
        @ViewBuilder func content() -> some View {
            let p_debug_view = 1
            makeTitle().padding(measure(&counter)).overlay { Text("overlay").bold() }
        }
        """)
        XCTAssertTrue(result.contains("let p_debug_view = 1"))
        XCTAssertEqual(result.components(separatedBy: "makeTitle()").count - 1, 1)
        XCTAssertEqual(result.components(separatedBy: "measure(&counter)").count - 1, 1)
        XCTAssertTrue(result.contains(".padding(measure(&counter))"))
        XCTAssertFalse(result.contains("Text(\"overlay\").bold()"))
    }

    func testUnsupportedDeclarationProducesAnActionableDiagnostic() throws
    {
        let initializer = try InitializerDeclSyntax("init() { value = 1 }")
        let context = BasicMacroExpansionContext(buildConfiguration: Self.p_configuration(debug: true))
        _ = try DebugViewMacro.expansion(of: "@debug_view", providingBodyFor: initializer, in: context)
        XCTAssertEqual(context.diagnostics.last?.message, "@debug_view requires a view-producing function or computed getter.")
        XCTAssertEqual(context.diagnostics.last?.diagMessage.severity, .error)
    }

    func p_expand(_ source: String) throws -> String
    {
        let declaration = try FunctionDeclSyntax("\(raw: source)")
        let context = BasicMacroExpansionContext(buildConfiguration: Self.p_configuration(debug: true))
        let items = try DebugViewMacro.expansion(of: "@debug_view", providingBodyFor: declaration, in: context)
        XCTAssertEqual(context.diagnostics.count, 1)
        if items.isEmpty { return declaration.body?.statements.formatted().description ?? "" }
        return CodeBlockItemListSyntax(items).formatted().description
    }

    static func p_configuration(debug: Bool) -> StaticBuildConfiguration
    {
        StaticBuildConfiguration(customConditions: debug ? ["DEBUG"] : [], languageVersion: .init(6), compilerVersion: .init(6, 4))
    }

    static var p_reminder: DiagnosticSpec {
        DiagnosticSpec(
            message: "@debug_view is temporary: remove it after diagnosing the error; only targets defining DEBUG are rewritten.",
            line: 1, column: 1, severity: .warning
        )
    }
}
#endif
