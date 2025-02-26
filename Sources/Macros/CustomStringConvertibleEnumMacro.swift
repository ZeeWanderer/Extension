import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics

public struct CustomStringConvertibleEnumMacro: MacroDiagnosticProtocol {}

extension CustomStringConvertibleEnumMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // This macro is only applicable to enums.
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            let diag = Diagnostic(
                node: node,
                message: MacroDiagnostic<Self>.onlyApplicableToEnum
            )
            context.diagnose(diag)
            return []
        }
        
        var switchCases: [String] = []
        for member in enumDecl.memberBlock.members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements {
                    let caseName = element.name.text
                    if let associatedValueClause = element.parameterClause {
                        let parameters = associatedValueClause.parameters
                        var patternBindings: [String] = []
                        var interpolatedValues: [String] = []
                        for (index, param) in parameters.enumerated() {
                            let paramName: String = {
                                if let name = param.firstName?.text, !name.isEmpty {
                                    return name
                                } else {
                                    return "value\(index)"
                                }
                            }()
                            patternBindings.append("let \(paramName)")
                            interpolatedValues.append("\\(\(paramName))")
                        }
                        let pattern = "case .\(caseName)(\(patternBindings.joined(separator: ", ")))"
                        let returnString = "\"\(caseName)(\(interpolatedValues.joined(separator: ", ")))\""
                        switchCases.append("\(pattern): return \(returnString)")
                    } else {
                        // For cases without associated values.
                        let pattern = "case .\(caseName)"
                        let returnString = "\"\(caseName)\""
                        switchCases.append("\(pattern): return \(returnString)")
                    }
                }
            }
        }
        
        let switchBody = switchCases.joined(separator: "\n")
        
        // Define the computed properties that will mimic String(describing:).
        let computedProperties: [(name: String, protocolName: String)] = [
            ("description", "CustomStringConvertible"),
            ("debugDescription", "CustomDebugStringConvertible"),
            ("testDescription", "CustomTestStringConvertible")
        ]
        
        let memberItems = computedProperties.map { (propName, _) in
            MemberBlockItemSyntax(decl: DeclSyntax("""
        public var \(raw: propName): String {
            switch self {
            \(raw: switchBody)
            }
        }
        """))
        }
        
        let inheritanceClause = InheritanceClauseSyntax(
            inheritedTypes: [
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("CustomStringConvertible")), trailingComma: .commaToken()),
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("CustomDebugStringConvertible")), trailingComma: .commaToken()),
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier("CustomTestStringConvertible")))
            ]
        )
        
        let extDecl = ExtensionDeclSyntax(
            extensionKeyword: .keyword(.extension),
            extendedType: type,
            inheritanceClause: inheritanceClause,
            memberBlock: MemberBlockSyntax {
                for item in memberItems {
                    item
                }
            }
        ).with(\.leadingTrivia, .newline)
        
        return [extDecl]
    }
}


