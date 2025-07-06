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

extension ActorProtocolExtensionMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        
        guard let arguments = node.arguments else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("name"))
            context.diagnose(diag)
            return []
        }
        
        guard let labeledArguments = arguments.as(LabeledExprListSyntax.self),
              let nameExpr = labeledArguments.first(where: { $0.label?.text == "name" })?.expression,
              let name = nameExpr.as(StringLiteralExprSyntax.self)?.representedLiteralValue else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("name"))
            context.diagnose(diag)
            return []
        }
        
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToClass)
            context.diagnose(diag)
            return []
        }
        
        let newExtensionDeclDef = ExtensionDeclSyntax(extendedType: TypeSyntax(stringLiteral: name)) {
            classDecl.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
                .map { fn in
                    var newFn = fn
                    
                    newFn.attributes = AttributeListSyntax {
                        let newAttrib: [AttributeSyntax] = fn.attributes.compactMap{ $0.as(AttributeSyntax.self)}.filter { fn in
                            fn.attributeName.trimmed.description != ActorProtocolIgnoreMacro.userFacingName
                        }
                        
                        for attribute in newAttrib {
                            attribute
                        }
                    }
                    
                    newFn.modifiers = DeclModifierListSyntax {
                        let newModifiers: [DeclModifierSyntax] = fn.modifiers.filter { mod in
                            mod.name.trimmed != TokenSyntax.keyword(.override)
                        }
                    }
                    
                    return newFn
                }
        }
  
        let newExtensionDecl = ExtensionDeclSyntax(extendedType: TypeSyntax(stringLiteral: "\(name)Actor")) {
            classDecl.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
                .compactMap { fn in
                    let isIgnored: Bool = fn.attributes.compactMap{ $0.as(AttributeSyntax.self)?.attributeName.trimmed.description }.contains(ActorProtocolIgnoreMacro.userFacingName)
                    
                    var newFn = fn
                    
                    newFn.modifiers = DeclModifierListSyntax {
                        let newModifiers: [DeclModifierSyntax] = fn.modifiers.filter { mod in
                            mod.name.trimmed != TokenSyntax.keyword(.override)
                        }
                    }
                    
                    return isIgnored ? nil : newFn
                }
        }

        return [newExtensionDeclDef, newExtensionDecl]
    }
}
