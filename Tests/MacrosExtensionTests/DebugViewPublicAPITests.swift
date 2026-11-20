//
//  DebugViewPublicAPITests.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

import XCTest
import SwiftUI
import MacrosExtension

@MainActor
internal final class P_DebugViewTrace
{
    var events: [String] = []

    func title() -> String { events.append("title"); return "Title" }
    func font() -> Font { events.append("font"); return .headline }
    func inset() -> CGFloat { events.append("inset"); return 4 }
    func condition() -> Bool { events.append("condition"); return false }
    func skipped() -> Bool { events.append("unexpected"); return true }
    func record(_ event: String) -> String { events.append(event); return event }
    func suspension() async { await Task.yield(); events.append("resumed") }
}

internal struct P_DebugViewBaseline: View
{
    let trace: P_DebugViewTrace

    var body: some View {
        VStack {
            Text(trace.title()).font(trace.font()).padding(trace.inset())
                .disabled(trace.condition() && trace.skipped())
        }
        .onAppear { trace.events.append("action") }
    }
}

internal struct P_DebugViewAnnotated: View
{
    let trace: P_DebugViewTrace

    @debug_view
    var body: some View {
        VStack {
            Text(trace.title()).font(trace.font()).padding(trace.inset())
                .disabled(trace.condition() && trace.skipped())
        }
        .onAppear { trace.events.append("action") }
    }

    @debug_view
    @ViewBuilder
    func text() -> Text {
        Text(trace.title()).font(trace.font()).bold()
    }

    @debug_view
    @ViewBuilder
    func asyncText() async throws -> Text {
        let _ = await trace.suspension()
        Text(trace.title()).font(trace.font()).bold()
    }

    @ViewBuilder
    @debug_view
    func branch(_ enabled: Bool) -> some View {
        if enabled {
            Text(trace.record("yes")).bold().padding()
        }
        else {
            Text(trace.record("no")).italic().padding()
        }
    }

    @debug_view
    var plainText: Text {
        Text(trace.title()).font(trace.font()).bold()
    }

    @debug_view
    func explicitReturn() -> Text {
        return Text(trace.title()).font(trace.font()).bold()
    }

    @debug_view
    var deferredArgument: some View {
        Text(trace.title()).p_ignoring(trace.record("unexpected")).padding()
    }
}

internal extension Text
{
    func p_ignoring(_ value: @autoclosure () -> String) -> Text { self }
}

@MainActor
final class DebugViewPublicAPITests: XCTestCase
{
    func testViewBodyPreservesEvaluationOrderAndDoesNotInvokeActions()
    {
        let trace = P_DebugViewTrace()
        let baseline = P_DebugViewBaseline(trace: trace).body
        let expected = trace.events
        trace.events = []
        let rewritten = P_DebugViewAnnotated(trace: trace).body

        XCTAssertEqual(expected, ["title", "font", "inset", "condition"])
        XCTAssertEqual(trace.events, expected)
        XCTAssertEqual(String(reflecting: type(of: rewritten)), String(reflecting: type(of: baseline)))
    }

    func testConcreteTextAPIsWorkWithAndWithoutExplicitBuilder()
    {
        let trace = P_DebugViewTrace()
        let view = P_DebugViewAnnotated(trace: trace)
        let _: Text = view.text()
        let _: Text = view.plainText
        let _: Text = view.explicitReturn()
        XCTAssertEqual(trace.events, ["title", "font", "title", "font", "title", "font"])
    }

    func testBranchesOnlyEvaluateTheSelectedPath()
    {
        let trace = P_DebugViewTrace()
        let view = P_DebugViewAnnotated(trace: trace)
        _ = view.branch(true)
        _ = view.branch(false)
        XCTAssertEqual(trace.events, ["yes", "no"])
    }

    func testAsyncBuilderRetainsActorContextAndEvaluationOrder() async throws
    {
        let trace = P_DebugViewTrace()
        let _: Text = try await P_DebugViewAnnotated(trace: trace).asyncText()
        XCTAssertEqual(trace.events, ["resumed", "title", "font"])
    }

    func testAutoclosureArgumentIsNotEagerlyEvaluated()
    {
        let trace = P_DebugViewTrace()
        _ = P_DebugViewAnnotated(trace: trace).deferredArgument
        XCTAssertEqual(trace.events, ["title"])
    }
}
