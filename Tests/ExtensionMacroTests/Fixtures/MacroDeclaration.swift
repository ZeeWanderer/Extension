//
//  MacroDeclaration.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

// Load the actual package plugin without coupling the subprocess to the test
// bundle's module search paths. Public import/wiring has separate usage tests.
@attached(body)
macro debug_view() = #externalMacro(module: "Macros", type: "DebugViewMacro")
