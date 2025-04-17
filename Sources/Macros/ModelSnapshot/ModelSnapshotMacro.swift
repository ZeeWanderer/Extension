//
//  ModelSnapshotMacro.swift
//  Extension
//
//  Created by zeewanderer on 10.04.2025.
//


import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct ModelSnapshotMacro: MacroDiagnosticProtocol {
}

extension ModelSnapshotMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self)
        else {
            let diag = Diagnostic(
                node: node,
                message: MacroDiagnostic<Self>.onlyApplicableToClass
            )
            context.diagnose(diag)
            return []
        }
        
        let typeName = classDecl.name.text
        
        var properties: [(name: String, type: String, isRelationship: Bool, useShallow: Bool)] = []
        
        for member in classDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation
            else { continue }
            
            let propName = pattern.identifier.text
            let typeString = typeAnnotation.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var ignore = false
            var useShallow = false
            let attributes = varDecl.attributes
            
            for attr in attributes {
                if let simpleAttr = attr.as(AttributeSyntax.self) {
                    let attrName = simpleAttr.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    if attrName == "SnapshotIgnore" {
                        ignore = true
                    }
                    if attrName == "SnapshotShallow" {
                        useShallow = true
                    }
                }
            }
                
            if ignore { continue }
            
            var isRelationship = false
            for attr in attributes {
                if let simpleAttr = attr.as(AttributeSyntax.self),
                   simpleAttr.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines) == "Relationship" {
                    isRelationship = true
                    break
                }
            }
            
            properties.append((name: propName, type: typeString, isRelationship: isRelationship, useShallow: useShallow))
        }
        
        var protocolFields = ""
        var shallowFields = ""
        var shallowInitBody = ""
        var snapshotFields = ""
        var snapshotInitBody = ""
        for prop in properties {
            if !prop.isRelationship {
                protocolFields += "var \(prop.name): \(prop.type) { get }"
                
                snapshotFields += "public let \(prop.name): \(prop.type)\n"
                snapshotInitBody += "self.\(prop.name) = model.\(prop.name)\n"
                
                shallowFields += "public let \(prop.name): \(prop.type)\n"
                shallowInitBody += "self.\(prop.name) = model.\(prop.name)\n"
            } else {
                if prop.type.hasPrefix("[") {
                    let trimmed = prop.type.dropFirst().dropLast()
                    let elementType = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
                    if prop.useShallow {
                        snapshotFields += "public let \(prop.name): [\(elementType).ShallowSnapshot]\n"
                        snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(elementType).ShallowSnapshot(from: $0) }\n"
                    } else {
                        snapshotFields += "public let \(prop.name): [\(elementType).Snapshot]\n"
                        snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(elementType).Snapshot(from: $0) }\n"
                    }
                } else {
                    if prop.type.hasSuffix("?") {
                        let underlying = String(prop.type.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                        if prop.useShallow {
                            snapshotFields += "public let \(prop.name): \(underlying).ShallowSnapshot?\n"
                            snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(underlying).ShallowSnapshot(from: $0) }\n"
                        } else {
                            snapshotFields += "public let \(prop.name): \(underlying).Snapshot?\n"
                            snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(underlying).Snapshot(from: $0) }\n"
                        }
                    } else {
                        if prop.useShallow {
                            snapshotFields += "public let \(prop.name): \(prop.type).ShallowSnapshot?\n"
                            snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(prop.type).ShallowSnapshot(from: $0) }\n"
                        } else {
                            snapshotFields += "public let \(prop.name): \(prop.type).Snapshot?\n"
                            snapshotInitBody += "self.\(prop.name) = model.\(prop.name).map { \(prop.type).Snapshot(from: $0) }\n"
                        }
                    }
                }
            }
        }
        
        let persistentIDDecl = """
        public let persistentModelID: PersistentIdentifier
        """
        let persistentIDInit = """
        self.persistentModelID = model.persistentModelID
        """
        
        let fullSource = """
               
               /// A protocol to streamline usage of ``Snapshot`` and ``ShallowSnapshot``
               public protocol SnapshotProtocol: Sendable {
                   var persistentModelID: PersistentIdentifier { get }
               \(protocolFields.indent(by: 4))
               }
               
               public struct Snapshot: SnapshotProtocol, Sendable {
               \(persistentIDDecl.indent(by: 4))
               \(snapshotFields.indent(by: 4))
                   public init(from model: \(typeName)) {
               \(persistentIDInit.indent(by: 8))
               \(snapshotInitBody.indent(by: 8))
                   }
               }
               
               public struct ShallowSnapshot: SnapshotProtocol, Sendable {
               \(persistentIDDecl.indent(by: 4))
               \(shallowFields.indent(by: 4))
                   public init(from model: \(typeName)) {
               \(persistentIDInit.indent(by: 8))
               \(shallowInitBody.indent(by: 8))
                   }
               }
               
               /// - Important: This version snapshots all the relationships that are not not marked by `SnapshotIgnore`
               /// If you need just the snapshot of the current object use ``shallowSnapshot`` instead
               public var snapshot: Snapshot {
                   return Snapshot(from: self)
               }
               public var shallowSnapshot: ShallowSnapshot {
                   return ShallowSnapshot(from: self)
               }
               
               """
        
        return [DeclSyntax(stringLiteral: fullSource)]
    }
}





