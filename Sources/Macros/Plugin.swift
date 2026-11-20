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
internal struct P_MacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FlatEnumMacro.self,
        RouterDestinationMacro.self,
        CustomStringConvertibleEnumMacro.self,
        ModelSnapshotMacro.self,
        SnapshotIgnoreMacro.self,
        SnapshotShallowMacro.self,
        ActorProtocolMacro.self,
        TransactionalMacro.self,
        RouterMacro.self,
        LogSubsystemMacro.self,
        LogCategoryMacro.self,
        DebugViewMacro.self,
    ]
}

#endif
