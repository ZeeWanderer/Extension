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
            throw CustomError.message("`@FlattenedEnum` can only be applied to enums")
        }
        
        let enumName = enumDecl.name.text
        let flatEnumName = "\(Self.flatEnumSuffix)\(enumName)"
        
        // Collect the cases in the original enum
        let cases = enumDecl.memberBlock.members.compactMap { member -> EnumCaseElementSyntax? in
            guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return nil }
            return enumCaseDecl.elements.first
        }
        
        // Create a list of EnumCaseDeclSyntax elements for each case
        let caseDecls = cases.map { caseElement in
            EnumCaseDeclSyntax(
                caseKeyword: .keyword(.case),
                elements: EnumCaseElementListSyntax {
                    EnumCaseElementSyntax(name: caseElement.name)
                }
            )
        }
        
        // Build the flat enum declaration with cases
        let flatEnumDecl = EnumDeclSyntax(
            modifiers: [DeclModifierSyntax(name: .identifier("public"))],
            name: .identifier(flatEnumName),
            genericParameterClause: nil, inheritanceClause: nil,
            genericWhereClause: nil,
            memberBlock: MemberBlockSyntax {
                for caseDecl in caseDecls {
                    MemberBlockItemSyntax(decl: caseDecl)
                }
            }
        ).with(\.leadingTrivia, .newline)
        
        // Create the property declaration
        // TODO: implement using SwiftSyntax
        let typePropertyDecl = DeclSyntax("""
        var \(raw: Self.flatPropertyName): \(raw: flatEnumName) {
            switch self {
            \(raw: cases.map { "case .\($0.name): return .\($0.name)" }.joined(separator: "\n"))
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
