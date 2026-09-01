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

public struct LogSubsystemMacro: P_MacroDiagnosticProtocol {}
public struct LogCategoryMacro: P_MacroDiagnosticProtocol {}

internal enum P_LogAccessLevel {
    case `public`
    case `package`
    case `internal`
    case `fileprivate`
    case `private`
    case none
}

internal func p_logAccessLevel(for declaration: some DeclGroupSyntax) -> P_LogAccessLevel {
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

internal func p_logAccessPrefix(_ level: P_LogAccessLevel) -> String {
    switch level {
    case .public: return "public "
    case .package: return "package "
    case .internal: return "internal "
    case .fileprivate, .private, .none:
        return ""
    }
}

internal func p_logAccessModifiers(_ level: P_LogAccessLevel) -> DeclModifierListSyntax? {
    let keyword: TokenSyntax?
    switch level {
    case .public:
        keyword = .keyword(.public)
    case .package:
        keyword = .keyword(.package)
    case .internal, .fileprivate, .private, .none:
        keyword = nil
    }
    guard let keyword else { return nil }
    return DeclModifierListSyntax { DeclModifierSyntax(name: keyword) }
}

extension LogSubsystemMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) || declaration.is(ActorDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }

        let access = p_logAccessLevel(for: declaration)
        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "LogSubsystemProtocol"))
            }
            )
        ) {
            DeclSyntax("""
                nonisolated \(raw: p_logAccessPrefix(access))static let logger = makeLogger()
                nonisolated \(raw: p_logAccessPrefix(access))static let signposter = makeSignposter()
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
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.error("can only be applied to a struct, class, enum, or actor."))
            context.diagnose(diag)
            return []
        }

        guard let arguments = node.arguments,
              let labeledArguments = arguments.as(LabeledExprListSyntax.self) else {
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.argumentMissing("subsystem"))
            context.diagnose(diag)
            return []
        }

        let subsystemExpr = labeledArguments.first(where: {
            $0.label?.text == "subsystem" || $0.label?.text == "of"
        })?.expression ?? labeledArguments.first?.expression

        guard let subsystemExpr else {
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.argumentMissing("subsystem"))
            context.diagnose(diag)
            return []
        }

        let access = p_logAccessLevel(for: declaration)
        var subsystemName = subsystemExpr.trimmedDescription
        if subsystemName.hasSuffix(".self") {
            subsystemName = String(subsystemName.dropLast(5))
        }

        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            inheritanceClause: InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "LogSubsystemCategoryProtocol"))
            }
            )
        ) {
            DeclSyntax("""
                \(raw: p_logAccessPrefix(access))typealias Subsystem = \(raw: subsystemName)
                nonisolated \(raw: p_logAccessPrefix(access))static let logger = makeLogger()
                nonisolated \(raw: p_logAccessPrefix(access))static let signposter = makeSignposter()
            """)
        }

        return [extensionDecl]
    }
}

#endif
