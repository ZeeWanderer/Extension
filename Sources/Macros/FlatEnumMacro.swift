//
//  FlatEnumMacro.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct FlatEnumMacro: MacroDiagnosticProtocol {
}

extension FlatEnumMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try FlatEnumMacroSupport.expansion(
            of: node,
            providingMembersOf: declaration,
            in: context,
            macroType: Self.self
        )
    }
}

#endif
