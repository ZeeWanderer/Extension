//
//  FlatEnumMacro.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct FlatEnumMacro {
    static let moduleName = "Macros"
    static let flatEnumSuffix = "Flat"
    static let flatPropertyName = "flat"
}

extension FlatEnumMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw CustomError.message("`@FlatEnum` can only be applied to enums")
        }
        
        let enumName = enumDecl.name.text
        let flatEnumName = "\(Self.flatEnumSuffix)\(enumName)"
        
        // Collect the cases in the original enum
        let cases = enumDecl.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)?.elements
        }.flatMap { $0 }
        
        // Create a list of EnumCaseDeclSyntax elements for each case, trimming trivia from names
        let caseDecls = cases.map { caseElement in
            let trimmedName = TokenSyntax.identifier(caseElement.name.text)
                .with(\.leadingTrivia, [])
                .with(\.trailingTrivia, [])
            return EnumCaseDeclSyntax(
                caseKeyword: .keyword(.case),
                elements: EnumCaseElementListSyntax {
                    EnumCaseElementSyntax(name: trimmedName)
                }
            )
        }
        
        // Check if the original enum conforms to CustomStringConvertible
        let conformsToCustomStringConvertible = enumDecl.inheritanceClause?.inheritedTypes.contains { inheritedType in
            if let simpleType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                return simpleType.name.text == "CustomStringConvertible"
            }
            return false
        } ?? false
        
        // If the original conforms, have the flat enum conform as well.
        let flatEnumInheritanceClause: InheritanceClauseSyntax? = conformsToCustomStringConvertible ? InheritanceClauseSyntax {
            InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("CustomStringConvertible")))
        } : nil
        
        // Build the flat enum declaration with cases
        let flatEnumDecl = EnumDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .identifier("public"))],
            name: .identifier(flatEnumName),
            genericParameterClause: nil,
            inheritanceClause: flatEnumInheritanceClause,
            genericWhereClause: nil,
            memberBlock: MemberBlockSyntax {
                for caseDecl in caseDecls {
                    MemberBlockItemSyntax(decl: caseDecl)
                }
                if conformsToCustomStringConvertible {
                    MemberBlockItemSyntax(decl: DeclSyntax("""
                    public var description: String { "\\(self)" }
                    """))
                }
            }
        ).with(\.leadingTrivia, .newline)
        
        // Create the property declaration using case names without trivia
        let typePropertyDecl = DeclSyntax("""
        var \(raw: Self.flatPropertyName): \(raw: flatEnumName) {
            switch self {
            \(raw: cases.map { "case .\($0.name.text): return .\($0.name.text)" }.joined(separator: "\n"))
            }
        }
        """)
        
        return [DeclSyntax(flatEnumDecl), typePropertyDecl]
    }
}

// Define a custom error to handle diagnostic messages
struct CustomError: Error, CustomStringConvertible {
    let description: String
    
    static func message(_ message: String) -> CustomError {
        CustomError(description: message)
    }
}

