//
//  FlatEnumMacro.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct FlatEnumMacro: MacroDiagnosticProtocol {
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
            let diag = Diagnostic(
                node: node,
                message: MacroDiagnostic<Self>.onlyApplicableToEnum
            )
            context.diagnose(diag)
            return []
        }
        
        let enumName = enumDecl.name.text
        var customFlatName: String? = nil
        var generateName = true
        var hasErrors = false
        
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            if let nameExpr = arguments.first(where: { arg in
                let label = arg.label?.text
                return label == "name" || label == "flatName"
            })?.expression {
                if let name = nameExpr.as(StringLiteralExprSyntax.self)?.representedLiteralValue,
                   !name.isEmpty {
                    customFlatName = name
                } else {
                    let diag = Diagnostic(node: nameExpr, message: MacroDiagnostic<Self>.error("name must be a non-empty string literal"))
                    context.diagnose(diag)
                    hasErrors = true
                }
            }
            
            if let generateExpr = arguments.first(where: { arg in
                let label = arg.label?.text
                return label == "generateName"
            })?.expression {
                if let boolLiteral = generateExpr.as(BooleanLiteralExprSyntax.self) {
                    generateName = boolLiteral.literal.tokenKind == .keyword(.true)
                } else {
                    let diag = Diagnostic(node: generateExpr, message: MacroDiagnostic<Self>.error("generateName must be a boolean literal"))
                    context.diagnose(diag)
                    hasErrors = true
                }
            }
        }
        
        if hasErrors {
            return []
        }
        
        let flatEnumName = customFlatName ?? (generateName ? "\(Self.flatEnumSuffix)\(enumName)" : "Flat")
        
        let hasStringMacro = enumDecl.attributes.contains { attribute in
            guard case .attribute(let attr) = attribute else { return false }
            return attr.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "CustomStringConvertibleEnum"
        }
        
        let cases = enumDecl.memberBlock.members.compactMap { member in
            member.decl.as(EnumCaseDeclSyntax.self)?.elements
        }.flatMap { $0 }
        
        let flatEnumDecl = EnumDeclSyntax(
            attributes: AttributeListSyntax {
                if hasStringMacro {
                    AttributeSyntax(
                        attributeName: IdentifierTypeSyntax(
                            name: .identifier("CustomStringConvertibleEnum")
                        )
                    )
                }
            },
            modifiers: [DeclModifierSyntax(name: .identifier("public"))],
            name: .identifier(flatEnumName),
            inheritanceClause: InheritanceClauseSyntax(
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(
                        type: IdentifierTypeSyntax(name: .identifier("Hashable"))
                    )
                }
            ),
            memberBlock: MemberBlockSyntax {
                for caseElement in cases {
                    MemberBlockItemSyntax(decl: EnumCaseDeclSyntax(
                        caseKeyword: .keyword(.case),
                        elements: EnumCaseElementListSyntax {
                            EnumCaseElementSyntax(
                                name: caseElement.name.trimmed
                            )
                        }
                    ))
                }
            }
        ).with(\.leadingTrivia, .newline)
        
        let typePropertyDecl = DeclSyntax("""
        public var \(raw: Self.flatPropertyName): \(raw: flatEnumName) {
            switch self {
            \(raw: cases.map { "case .\($0.name.text): return .\($0.name.text)" }.joined(separator: "\n"))
            }
        }
        """)
        
        return [DeclSyntax(flatEnumDecl), typePropertyDecl]
    }
}

#endif
