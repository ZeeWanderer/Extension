//
//  ActorProtocolMacro.swift
//  Extension
//
//  Created by zeewanderer on 02.07.2025.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct ActorProtocolMacro: MacroDiagnosticProtocol {}

extension ActorProtocolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToProtocol)
            context.diagnose(diag)
            return []
        }

        let protoName = protocolDecl.name.text
        let actorProtoName = "Actor\(protoName)"

        let vars = protocolDecl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .map { v -> VariableDeclSyntax in
                var newV = v

                let newBindings = newV.bindings.map { binding in
                    
                    var newBinding = binding
                    
                    if var newAccessorBlock = binding.accessorBlock {
                        let accessors = newAccessorBlock.accessors.as(AccessorDeclListSyntax.self)
   
                        let newAccessors: [AccessorDeclListSyntax.Element] = accessors?.map { accessor in
                            var newAccessor = accessor
                            if newAccessor.effectSpecifiers?.asyncSpecifier == nil {
                                var newEffectSpecs = accessor.effectSpecifiers ?? AccessorEffectSpecifiersSyntax()
                                newEffectSpecs.asyncSpecifier = .keyword(.async)
                                // TODO: figure this out
                                // newAccessor.effectSpecifiers = newEffectSpecs
                            }
                            return newAccessor
                        } ?? []
                        
                        newAccessorBlock.accessors = .accessors(
                            AccessorDeclListSyntax{
                                newAccessors
                            }
                        )
                        newBinding.accessorBlock = newAccessorBlock
                    }
                    
                    return newBinding
                }
                
                newV.bindings = PatternBindingListSyntax {
                    newBindings
                }
                
                return newV
            }
        
        let methods = protocolDecl.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .map { fn -> FunctionDeclSyntax in
                var newFn = fn
                
                var newEffectSpecs = newFn.signature.effectSpecifiers ?? FunctionEffectSpecifiersSyntax()
                if newEffectSpecs.asyncSpecifier == nil {
                    newEffectSpecs.asyncSpecifier = .keyword(.async)
                }
                
                newFn.signature.effectSpecifiers = newEffectSpecs
                return newFn
            }

        let peerProtocol = ProtocolDeclSyntax(modifiers: protocolDecl.modifiers ,name: .identifier(actorProtoName), inheritanceClause: protocolDecl.inheritanceClause) {
            MemberBlockItemListSyntax {
                vars
                methods
            }
        }

        return [DeclSyntax(peerProtocol)]
    }
}
