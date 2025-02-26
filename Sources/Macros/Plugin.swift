//
//  Plugin.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlatEnumMacro.self,
        CustomStringConvertibleEnumMacro.self
    ]
}
