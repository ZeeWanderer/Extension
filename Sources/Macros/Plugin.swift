//
//  Plugin.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

#if canImport(SwiftCompilerPlugin) && canImport(SwiftSyntaxMacros)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlatEnumMacro.self,
        CustomStringConvertibleEnumMacro.self,
        ModelSnapshotMacro.self,
        SnapshotIgnoreMacro.self,
        SnapshotShallowMacro.self,
        ActorProtocolMacro.self,
        ActorProtocolExtensionMacro.self,
        ActorProtocolIgnoreMacro.self,
        TransactionalMacro.self,
        LogSubsystemMacro.self,
        LogCategoryMacro.self,
    ]
}

#endif
