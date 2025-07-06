//
//  ActorProtocolIgnoreMacro.swift
//  Extension
//
//  Created by zeewanderer on 06.07.2025.
//


import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct ActorProtocolIgnoreMacro: MacroDiagnosticProtocol {}

extension ActorProtocolIgnoreMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}
