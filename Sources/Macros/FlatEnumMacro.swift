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
        let flatEnumName = "\(Self.flatEnumSuffix)\(enumName)"
        
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
