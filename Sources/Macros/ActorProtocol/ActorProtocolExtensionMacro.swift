//
//  ActorProtocolExtensionMacro.swift
//  Extension
//
//  Created by zeewanderer on 02.07.2025.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct ActorProtocolExtensionMacro: MacroDiagnosticProtocol {}

extension ActorProtocolExtensionMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let extensionDecl = declaration.as(ExtensionDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToExtension)
            context.diagnose(diag)
            return []
        }

        var newExtensionDecl = extensionDecl
        let newAttributes: [AttributeListSyntax.Element] = extensionDecl.attributes
            .compactMap { attribute in
                
                guard let attributeS = attribute.as(AttributeSyntax.self), attributeS.attributeName.trimmed.description != "ActorProtocolExtension"
                else { return nil }
                
                return attribute
        }
        
        newExtensionDecl.attributes = AttributeListSyntax {
            newAttributes
        }
        newExtensionDecl.extendedType = "\(raw: extensionDecl.extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines))Actor"

        return [DeclSyntax(newExtensionDecl)]
    }
}
