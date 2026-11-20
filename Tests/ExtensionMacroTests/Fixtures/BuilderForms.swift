//
//  BuilderForms.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

import SwiftUI

extension LocalizedStringResource {
    static var p_sample: Self { Self("sample") }
}

struct P_BuilderFixture: View {
    let flag = true
    let number = 1
    @State var enabled = false

    #if DIAGNOSTIC
    @debug_view
    #endif
    var body: some View {
        let p_debug_view = "does not collide"
        VStack {
            Text(.p_sample).font(.headline).padding()
            ForEach(0..<3) { index in
                if index == 1 {
                    Text(p_debug_view).bold().padding()
                }
                else {
                    Text("Other").italic().padding()
                }
            }
            Button { p_action().first().second() } label: {
                Text("Action").bold().padding()
            }
            Button(action: { p_action().first().second() }) {
                Text("Other action").bold().padding()
            }
            Button(action: { p_action().first().second() }, label: {
                Text("Explicit label").bold().padding()
            })
            Toggle(isOn: $enabled) { Text("Toggle").bold().padding() }
        }
        .overlay { Text("Overlay").bold().padding() }
        .onAppear { p_action().first().second() }
        .task { await p_asyncAction() }
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    @ViewBuilder
    var p_explicitBuilder: some View {
        if #available(macOS 99, *) {
            Text("Future").bold().padding()
        }
        else if flag {
            Text("Flag").bold().padding()
        }
        else {
            Text("Fallback").bold().padding()
        }
        switch number {
        case 1: Text("One").bold().padding()
        default: Text("Other").bold().padding()
        }
        #if FEATURE
        Text("Inactive branch").p_nonexistentModifier().padding()
        #else
        Text("Normal").bold().padding()
        #endif
    }

    @ViewBuilder
    #if DIAGNOSTIC
    @debug_view
    #endif
    func p_builderFunction() -> some View {
        Text(.p_sample).bold().padding()
        Text("Second").italic().padding()
    }

    @ViewBuilder
    #if DIAGNOSTIC
    @debug_view
    #endif
    var p_reverseAttributeOrder: some View {
        Text("Reverse").bold().padding()
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    func p_concreteText() -> Text {
        Text(.p_sample).font(.headline).bold()
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    var p_ordinaryGetter: Text {
        Text("Plain").font(.headline).bold()
    }

    var p_explicitGetter: Text {
        #if DIAGNOSTIC
        @debug_view
        #endif
        get { Text("Explicit getter").font(.headline).bold() }
    }

    @ViewBuilder
    var p_effectfulGetter: some View {
        #if DIAGNOSTIC
        @debug_view
        #endif
        get async throws {
            let _ = await p_asyncAction()
            Text("Effectful getter").bold().padding()
        }
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    func p_contextualText() -> Text {
        .init("Contextual").font(.headline)
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    func p_conditionalText() -> Text {
        if flag { Text("Yes").bold() } else { Text("No").bold() }
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    func p_optionalText(_ value: Text?) -> Text? {
        value?.font(.headline).bold()
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    @ViewBuilder
    func p_asyncBuilder() async throws -> some View {
        let _ = await p_asyncAction()
        Text("Async").bold().padding()
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    @ViewBuilder
    func p_typedThrowingBuilder() throws(P_Failure) -> Text {
        Text("Typed error").font(.headline).bold()
    }

    #if DIAGNOSTIC
    @debug_view
    #endif
    @ViewBuilder
    func p_rethrowingBuilder(_ make: () throws -> Text) rethrows -> some View {
        try make()
        Text("Rethrowing").bold().padding()
    }

    func p_action() -> P_Action { P_Action() }
    func p_asyncAction() async {}
}

struct P_Action {
    func first() -> Self { self }
    func second() {}
}

enum P_Failure: Error { case sample }
