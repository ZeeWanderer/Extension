//
//  RouterMacro.swift
//  Extension
//
//  Created by zeewanderer on 03.02.2026.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct RouterMacro: MacroDiagnosticProtocol {}

private enum RouterAccessLevel {
    case `public`
    case `package`
    case `internal`
    case `fileprivate`
    case `private`
    case none
}

private func routerAccessLevel(for declaration: some DeclGroupSyntax) -> RouterAccessLevel {
    for modifier in declaration.modifiers {
        switch modifier.name.tokenKind {
        case .keyword(.public), .keyword(.open):
            return .public
        case .keyword(.package):
            return .package
        case .keyword(.internal):
            return .internal
        case .keyword(.fileprivate):
            return .fileprivate
        case .keyword(.private):
            return .private
        default:
            continue
        }
    }
    return .none
}

private func routerAccessPrefix(_ level: RouterAccessLevel) -> String {
    switch level {
    case .public: return "public "
    case .package: return "package "
    case .internal, .fileprivate, .private, .none:
        return ""
    }
}

private func hasRouterProtocolConformance(_ declaration: some DeclGroupSyntax) -> Bool {
    func inheritsRouterProtocol(_ clause: InheritanceClauseSyntax?) -> Bool {
        guard let clause else { return false }
        return clause.inheritedTypes.contains { inherited in
            let name = inherited.type.trimmedDescription
            return name == "RouterProtocol" || name.hasSuffix(".RouterProtocol")
        }
    }
    
    if let decl = declaration.as(ClassDeclSyntax.self) {
        return inheritsRouterProtocol(decl.inheritanceClause)
    }
    if let decl = declaration.as(StructDeclSyntax.self) {
        return inheritsRouterProtocol(decl.inheritanceClause)
    }
    if let decl = declaration.as(EnumDeclSyntax.self) {
        return inheritsRouterProtocol(decl.inheritanceClause)
    }
    if let decl = declaration.as(ActorDeclSyntax.self) {
        return inheritsRouterProtocol(decl.inheritanceClause)
    }
    
    return false
}

private func hasViewTypesMember(_ declaration: some DeclGroupSyntax) -> Bool {
    for member in declaration.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        for binding in varDecl.bindings {
            if let ident = binding.pattern.as(IdentifierPatternSyntax.self),
               ident.identifier.text == "viewTypes" {
                return true
            }
        }
    }
    return false
}

extension RouterMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self)
                || declaration.is(ClassDeclSyntax.self)
                || declaration.is(EnumDeclSyntax.self)
                || declaration.is(ActorDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }
        
        if hasViewTypesMember(declaration) {
            return []
        }
        
        let access = routerAccessLevel(for: declaration)
        let decl = DeclSyntax("\(raw: routerAccessPrefix(access))static let viewTypes = computeViewTypes()")
        return [decl]
    }
}

extension RouterMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self)
                || declaration.is(ClassDeclSyntax.self)
                || declaration.is(EnumDeclSyntax.self)
                || declaration.is(ActorDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }
        
        if hasRouterProtocolConformance(declaration) {
            return []
        }
        
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "RouterProtocol"))
                }
            )
        ) {}
        
        return [extensionDecl]
    }
}

#endif
