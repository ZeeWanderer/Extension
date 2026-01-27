//
//  LogMacros.swift
//  Extension
//
//  Created by zeewanderer on 27.01.2026.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct LogSubsystemMacro: MacroDiagnosticProtocol {}
public struct LogCategoryMacro: MacroDiagnosticProtocol {}

private func accessModifierPrefix(for declaration: some DeclGroupSyntax) -> String {
    for modifier in declaration.modifiers {
        switch modifier.name.text {
        case "public":
            return "public "
        case "open":
            return "public "
        case "internal":
            return "internal "
        case "fileprivate":
            return "fileprivate "
        case "private":
            return "private "
        default:
            continue
        }
    }
    return ""
}

extension LogSubsystemMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) || declaration.is(ActorDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }
        
        let access = accessModifierPrefix(for: declaration)
        let extensionDecl = ExtensionDeclSyntax(extendedType: type, inheritanceClause: InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "LogSubsystemProtocol"))
            }
        )) {
            DeclSyntax("""
                nonisolated \(raw: access)static let logger = makeLogger()
                nonisolated \(raw: access)static let signposter = makeSignposter()
            """)
        }
        
        return [extensionDecl]
    }
}

extension LogCategoryMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) || declaration.is(ActorDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }
        
        guard let arguments = node.arguments,
              let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("subsystem"))
            context.diagnose(diag)
            return []
        }
        
        let subsystemExpr = labeledArguments.first(where: {
            $0.label?.text == "subsystem" || $0.label?.text == "of"
        })?.expression ?? labeledArguments.first?.expression
        
        guard let subsystemExpr else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("subsystem"))
            context.diagnose(diag)
            return []
        }
        
        let access = accessModifierPrefix(for: declaration)
        var subsystemName = subsystemExpr.trimmedDescription
        if subsystemName.hasSuffix(".self") {
            subsystemName = String(subsystemName.dropLast(5))
        }
        
        let extensionDecl = ExtensionDeclSyntax(extendedType: type, inheritanceClause: InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "LogSubsystemCategoryProtocol"))
            }
        )) {
            DeclSyntax("""
                \(raw: access)typealias Subsystem = \(raw: subsystemName)
                nonisolated \(raw: access)static let logger = makeLogger()
                nonisolated \(raw: access)static let signposter = makeSignposter()
            """)
        }
        
        return [extensionDecl]
    }
}

#endif
