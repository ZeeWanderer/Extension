//
//  RouterDestinationMacro.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct RouterDestinationMacro: MacroDiagnosticProtocol {}

private func hasRouterDestinationConformance(_ declaration: some DeclGroupSyntax) -> Bool {
    func inheritsRouterDestination(_ clause: InheritanceClauseSyntax?) -> Bool {
        guard let clause else { return false }
        return clause.inheritedTypes.contains { inherited in
            let name = inherited.type.trimmedDescription
            return name == "RouterDestination" || name.hasSuffix(".RouterDestination")
        }
    }
    
    if let decl = declaration.as(EnumDeclSyntax.self) {
        return inheritsRouterDestination(decl.inheritanceClause)
    }
    
    return false
}

extension RouterDestinationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try FlatEnumMacroSupport.expansion(
            of: node,
            providingMembersOf: declaration,
            in: context,
            macroType: Self.self,
            allowArguments: false,
            forceFlatName: "Flat",
            defaultGenerateName: false
        )
    }
}

extension RouterDestinationMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToEnum)
            context.diagnose(diag)
            return []
        }
        
        if hasRouterDestinationConformance(declaration) {
            return []
        }
        
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "RouterDestination"))
                }
            )
        ) {}
        
        return [extensionDecl]
    }
}

#endif
