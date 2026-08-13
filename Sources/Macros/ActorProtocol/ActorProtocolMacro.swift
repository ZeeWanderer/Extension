//
//  ActorProtocolMacro.swift
//  Extension
//
//  Created by zeewanderer on 02.07.2025.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct ActorProtocolMacro: P_MacroDiagnosticProtocol {}

extension ActorProtocolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: P_MacroDiagnostic<Self>.onlyApplicableToProtocol)
            context.diagnose(diag)
            return []
        }

        let protoName = protocolDecl.name.text
        let actorProtoName = "\(protoName)Actor"

        let members = protocolDecl.memberBlock.members.map { member -> MemberBlockItemSyntax in
            guard var function = member.decl.as(FunctionDeclSyntax.self) else {
                return member
            }

            var effectSpecifiers = function.signature.effectSpecifiers ?? FunctionEffectSpecifiersSyntax()
            if effectSpecifiers.asyncSpecifier == nil {
                effectSpecifiers.asyncSpecifier = .keyword(.async)
            }
            function.signature.effectSpecifiers = effectSpecifiers

            var transformed = member
            transformed.decl = DeclSyntax(function)
            return transformed
        }

        var newInheritanceClause = protocolDecl.inheritanceClause ?? InheritanceClauseSyntax(inheritedTypes: InheritedTypeListSyntax())
        var newInheritedTypes = protocolDecl.inheritanceClause?.inheritedTypes.map { $0.trimmed as InheritedTypeSyntax } ?? []
        
        newInheritedTypes.append(.init(type: TypeSyntax("Actor")))
        newInheritanceClause.inheritedTypes = .init {
            newInheritedTypes
        }
        
        let peerProtocol = ProtocolDeclSyntax(modifiers: protocolDecl.modifiers ,name: .identifier(actorProtoName), inheritanceClause: newInheritanceClause) {
            MemberBlockItemListSyntax {
                members
            }
        }

        return [DeclSyntax(peerProtocol)]
    }
}

#endif
