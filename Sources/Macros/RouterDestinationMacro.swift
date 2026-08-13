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

public struct RouterDestinationMacro: P_MacroDiagnosticProtocol {}

internal func p_hasRouterDestinationConformance(_ declaration: some DeclGroupSyntax) -> Bool {
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
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self),
           let generateExpression = arguments.first(where: {
               $0.label?.text == "generateFlat"
           })?.expression
        {
            guard let boolean = generateExpression.as(BooleanLiteralExprSyntax.self)
            else
            {
                let diagnostic = Diagnostic(
                    node: generateExpression,
                    message: P_MacroDiagnostic<Self>.error(
                        "generateFlat must be a boolean literal"
                    )
                )
                context.diagnose(diagnostic)
                return []
            }

            if boolean.literal.tokenKind == .keyword(.false)
            {
                return []
            }
        }

        return try P_FlatEnumMacroSupport.expansion(
            of: node,
            providingMembersOf: declaration,
            in: context,
            macroType: Self.self,
            allowArguments: true,
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
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.onlyApplicableToEnum)
            context.diagnose(diag)
            return []
        }
        
        if p_hasRouterDestinationConformance(declaration) {
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
