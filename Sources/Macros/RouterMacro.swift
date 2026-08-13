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

private let routerProtocolNames: Set<String> = [
    "RouterProtocol",
    "SinglePathRouterProtocol",
    "DictionaryRouterProtocol",
    "RouterViewProvider",
    "RouterViewRegistryProtocol",
]

private func routerConformances(
    of declaration: some DeclGroupSyntax
) -> Set<String> {
    func inheritedProtocolNames(
        _ clause: InheritanceClauseSyntax?
    ) -> Set<String> {
        guard let clause else { return [] }
        return Set(clause.inheritedTypes.compactMap { inherited in
            let qualifiedName = inherited.type.trimmedDescription
            return routerProtocolNames.first { name in
                qualifiedName == name || qualifiedName.hasSuffix(".\(name)")
            }
        })
    }

    if let decl = declaration.as(ClassDeclSyntax.self) {
        return inheritedProtocolNames(decl.inheritanceClause)
    }
    if let decl = declaration.as(StructDeclSyntax.self) {
        return inheritedProtocolNames(decl.inheritanceClause)
    }
    if let decl = declaration.as(EnumDeclSyntax.self) {
        return inheritedProtocolNames(decl.inheritanceClause)
    }
    if let decl = declaration.as(ActorDeclSyntax.self) {
        return inheritedProtocolNames(decl.inheritanceClause)
    }

    return []
}

private func hasRouterMember(
    named name: String,
    isStatic expectedStatic: Bool? = nil,
    in declaration: some DeclGroupSyntax
) -> Bool {
    for member in declaration.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        let isStatic = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static)
                || modifier.name.tokenKind == .keyword(.class)
        }
        if let expectedStatic, expectedStatic != isStatic { continue }

        for binding in varDecl.bindings {
            if let ident = binding.pattern.as(IdentifierPatternSyntax.self),
               ident.identifier.text == name {
                return true
            }
        }
    }
    return false
}

private func hasDirectViewProviderMember(
    _ declaration: some DeclGroupSyntax
) -> Bool {
    declaration.memberBlock.members.contains { member in
        guard let function = member.decl.as(FunctionDeclSyntax.self),
              function.name.text == "view",
              !function.modifiers.contains(where: {
                  $0.name.tokenKind == .keyword(.static)
                      || $0.name.tokenKind == .keyword(.class)
              })
        else {
            return false
        }

        let parameters = function.signature.parameterClause.parameters
        guard parameters.count == 2 else { return false }
        let first = parameters[parameters.startIndex]
        let second = parameters[parameters.index(after: parameters.startIndex)]
        return first.firstName.text == "for" && second.firstName.text == "context"
    }
}

extension RouterMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a class."))
            context.diagnose(diag)
            return []
        }
        
        guard hasRouterMember(named: "views", isStatic: true, in: declaration),
              !hasRouterMember(named: "viewTypes", isStatic: true, in: declaration)
        else {
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
        guard declaration.is(ClassDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a class."))
            context.diagnose(diag)
            return []
        }
        
        let existingConformances = routerConformances(of: declaration)
        var addedConformances: [String] = []

        if existingConformances.isDisjoint(with: routerProtocolNames)
        {
            if hasRouterMember(named: "path", isStatic: false, in: declaration)
            {
                addedConformances.append("RouterProtocol")
                addedConformances.append("SinglePathRouterProtocol")
            }
            else if hasRouterMember(named: "paths", isStatic: false, in: declaration)
            {
                addedConformances.append("RouterProtocol")
                addedConformances.append("DictionaryRouterProtocol")
            }
            else
            {
                addedConformances.append("RouterProtocol")
            }
        }

        let hasViewProvider = existingConformances.contains("RouterViewProvider")
            || existingConformances.contains("RouterViewRegistryProtocol")

        if hasRouterMember(named: "views", isStatic: true, in: declaration),
           !hasViewProvider
        {
            if !existingConformances.contains("RouterViewProvider")
            {
                addedConformances.append("RouterViewProvider")
            }
            addedConformances.append("RouterViewRegistryProtocol")
        }
        else if hasDirectViewProviderMember(declaration),
                !hasViewProvider
        {
            addedConformances.append("RouterViewProvider")
        }

        guard !addedConformances.isEmpty else
        {
            return []
        }

        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax {
                    for conformance in addedConformances
                    {
                        InheritedTypeSyntax(
                            type: TypeSyntax(stringLiteral: conformance)
                        )
                    }
                }
            )
        ) {}
        
        return [extensionDecl]
    }
}

#endif
