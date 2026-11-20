//
//  DebugViewMacro.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the temporary `@debug_view` diagnostic macro.
public struct DebugViewMacro: BodyMacro
{
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax]
    {
        context.diagnose(Diagnostic(node: node, message: P_DebugViewDiagnostic.temporary))
        guard let body = declaration.body else { return [] }

        // This is the consuming target's configuration, never the plugin's own
        // compilation mode. When an older host supplies no configuration, fail
        // closed: in particular, never rewrite a release client's body. An
        // empty expansion keeps the compiler's original body, without parsing
        // a replacement copy (which can itself affect result-builder checking).
        guard let configuration = context.buildConfiguration,
              let isDebug = try? configuration.isCustomConditionSet(name: "DEBUG") else {
            context.diagnose(Diagnostic(node: node, message: P_DebugViewDiagnostic.configurationUnavailable))
            return []
        }
        guard isDebug else { return [] }

        let isBuilder: Bool
        if let function = declaration.as(FunctionDeclSyntax.self), function.signature.returnClause != nil {
            isBuilder = p_hasViewBuilder(function.attributes)
        }
        else if let accessor = declaration.as(AccessorDeclSyntax.self), accessor.accessorSpecifier.text == "get" {
            // SwiftSyntax supplies an implicit getter for a shorthand computed
            // property. Its property's attributes remain in lexicalContext.
            let property = context.lexicalContext.compactMap { $0.as(VariableDeclSyntax.self) }.first
            isBuilder = p_hasViewBuilder(accessor.attributes)
                || property.map { p_hasViewBuilder($0.attributes) || $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body" } == true
        }
        else {
            context.diagnose(Diagnostic(node: node, message: P_DebugViewDiagnostic.unsupportedDeclaration))
            return []
        }

        // A parameterless helper cannot rethrow an error from a captured
        // closure. Do not weaken the original declaration's effect contract.
        if isBuilder, declaration.as(FunctionDeclSyntax.self)?.signature.effectSpecifiers?.throwsClause?.throwsSpecifier.text == "rethrows" {
            context.diagnose(Diagnostic(node: node, message: P_DebugViewDiagnostic.rethrowingBuilder))
            return []
        }

        let rewriter = P_DebugViewRewriter(context: context)
        var result = rewriter.statements(body.statements, isBuilder: isBuilder)
        guard CodeBlockItemListSyntax(result).description != body.statements.description else { return [] }
        if isBuilder {
            // Swift 6.4 cannot reliably type-check bindings introduced directly
            // into a body-macro/result-builder combination. A local builder
            // function gives the rewritten statements an independent scope.
            // The explicit outer return bypasses only the outer transform; the
            // original ViewBuilder semantics are retained on this helper.
            let function = declaration.as(FunctionDeclSyntax.self)
            let property = context.lexicalContext.compactMap { $0.as(VariableDeclSyntax.self) }.first
            let resultType = function?.signature.returnClause?.type
                ?? property?.bindings.first?.typeAnnotation?.type ?? TypeSyntax("some View")
            let functionEffects = function?.signature.effectSpecifiers
            let accessorEffects = declaration.as(AccessorDeclSyntax.self)?.effectSpecifiers
            let effects = functionEffects.map(Syntax.init) ?? accessorEffects.map(Syntax.init)
            let name = context.makeUniqueName("p_debug_view_body")
            let effectText = effects.map { $0.trimmedDescription + " " } ?? ""
            let helper = try FunctionDeclSyntax("@ViewBuilder func \(name)() \(raw: effectText)-> \(resultType.trimmed)") {
                CodeBlockItemListSyntax(result)
            }
            let prefix = (functionEffects?.throwsClause ?? accessorEffects?.throwsClause != nil ? "try " : "")
                + (functionEffects?.asyncSpecifier ?? accessorEffects?.asyncSpecifier != nil ? "await " : "")
            return [
                CodeBlockItemSyntax(item: .decl(DeclSyntax(helper))),
                CodeBlockItemSyntax("return \(raw: prefix)\(name)()"),
            ]
        }
        // A single-expression ordinary function/getter loses its implicit
        // return when we introduce local bindings.
        if !isBuilder, body.statements.count == 1,
           body.statements.first?.item.is(ExprSyntax.self) == true,
           result.count > 1, let expression = result.last?.item.as(ExprSyntax.self) {
            result[result.count - 1] = CodeBlockItemSyntax(item: .stmt(StmtSyntax(ReturnStmtSyntax(expression: expression))))
        }
        return result
    }

    internal static func p_hasViewBuilder(_ attributes: AttributeListSyntax) -> Bool
    {
        attributes.contains { attribute in
            guard let type = attribute.as(AttributeSyntax.self)?.attributeName else { return false }
            return type.as(IdentifierTypeSyntax.self)?.name.text == "ViewBuilder"
                || type.as(MemberTypeSyntax.self)?.name.text == "ViewBuilder"
        }
    }
}

internal enum P_DebugViewDiagnostic: DiagnosticMessage
{
    case temporary
    case configurationUnavailable
    case unsupportedDeclaration
    case rethrowingBuilder

    var message: String {
        switch self {
        case .temporary:
            "@debug_view is temporary: remove it after diagnosing the error; only targets defining DEBUG are rewritten."
        case .configurationUnavailable:
            "@debug_view could not read the target's DEBUG condition; the original body is unchanged."
        case .unsupportedDeclaration:
            "@debug_view requires a view-producing function or computed getter."
        case .rethrowingBuilder:
            "@debug_view leaves rethrows builder helpers unchanged; annotate a non-rethrowing view-producing helper instead."
        }
    }

    var severity: DiagnosticSeverity { self == .unsupportedDeclaration ? .error : .warning }
    var diagnosticID: MessageID { MessageID(domain: "DebugViewMacro", id: String(describing: self)) }
}
#endif
