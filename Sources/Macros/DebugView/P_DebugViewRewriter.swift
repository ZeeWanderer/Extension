//
//  P_DebugViewRewriter.swift
//  Extension
//
//  Created by zeewanderer on 21.09.2026.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros)
import SwiftSyntax
import SwiftSyntaxMacros

/// Syntax-only, deliberately conservative inference boundaries. In particular,
/// arguments remain in their original calls and arbitrary closures are opaque.
internal final class P_DebugViewRewriter: SyntaxRewriter
{
    let context: any MacroExpansionContext

    init(context: any MacroExpansionContext)
    {
        self.context = context
        super.init(viewMode: .sourceAccurate)
    }

    func statements(_ source: CodeBlockItemListSyntax, isBuilder: Bool) -> [CodeBlockItemSyntax]
    {
        var result: [CodeBlockItemSyntax] = []
        for item in source {
            let expression = item.item.as(ExprSyntax.self) ?? item.item.as(ExpressionStmtSyntax.self)?.expression
            if isBuilder, let branch = expression?.as(IfExprSyntax.self) {
                result.append(item.with(\.item, .expr(ExprSyntax(rewriteIf(branch)))))
            }
            else if isBuilder, let branch = expression?.as(SwitchExprSyntax.self) {
                result.append(item.with(\.item, .expr(ExprSyntax(rewriteSwitch(branch)))))
            }
            else if let expression {
                let visited = rewrite(expression).cast(ExprSyntax.self)
                let value = split(visited, into: &result)
                result.append(item.with(\.item, .expr(value)))
            }
            else if var returnStatement = item.item.as(ReturnStmtSyntax.self), let expression = returnStatement.expression {
                let visited = rewrite(expression).cast(ExprSyntax.self)
                returnStatement.expression = split(visited, into: &result)
                result.append(item.with(\.item, .stmt(StmtSyntax(returnStatement))))
            }
            else if isBuilder, let conditional = item.item.as(IfConfigDeclSyntax.self) {
                result.append(item.with(\.item, .decl(DeclSyntax(rewriteConditional(conditional)))))
            }
            else {
                result.append(rewrite(item).cast(CodeBlockItemSyntax.self))
            }
        }
        return result
    }

    func split(_ expression: ExprSyntax, into output: inout [CodeBlockItemSyntax]) -> ExprSyntax
    {
        // Do not move work across optional chains, try/await, casts, closures,
        // or context-dependent leading-dot expressions. Only a plain spine of
        // method calls is split; no arguments are hoisted or evaluated twice.
        var calls: [FunctionCallExprSyntax] = []
        var current = expression
        while let call = current.as(FunctionCallExprSyntax.self) {
            calls.append(call)
            if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
                guard let base = member.base else { return expression }
                if base.is(FunctionCallExprSyntax.self) {
                    current = base
                    continue
                }
                guard isExplicitReceiver(base) else { return expression }
            }
            else if !isExplicitReceiver(call.calledExpression) {
                return expression
            }
            break
        }
        guard calls.count > 1 else { return expression }

        var reference: ExprSyntax?
        for original in calls.reversed() {
            var call = original
            if let reference, var member = call.calledExpression.as(MemberAccessExprSyntax.self) {
                member.base = reference
                call.calledExpression = ExprSyntax(member)
            }
            let name = context.makeUniqueName("p_debug_view")
            let binding = PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: name),
                initializer: InitializerClauseSyntax(value: call.trimmed)
            )
            let variable = VariableDeclSyntax(
                leadingTrivia: call.leadingTrivia,
                bindingSpecifier: .keyword(.let),
                bindings: PatternBindingListSyntax([binding])
            )
            output.append(CodeBlockItemSyntax(item: .decl(DeclSyntax(variable))))
            reference = ExprSyntax(DeclReferenceExprSyntax(baseName: name))
        }
        return reference ?? expression
    }

    func isExplicitReceiver(_ expression: ExprSyntax) -> Bool
    {
        if expression.is(DeclReferenceExprSyntax.self) || expression.is(SuperExprSyntax.self) { return true }
        if let member = expression.as(MemberAccessExprSyntax.self), let base = member.base {
            return isExplicitReceiver(base)
        }
        if let specialization = expression.as(GenericSpecializationExprSyntax.self) {
            return isExplicitReceiver(specialization.expression)
        }
        return false
    }

    func rewriteIf(_ source: IfExprSyntax) -> IfExprSyntax
    {
        var result = source
        result.body.statements = CodeBlockItemListSyntax(statements(source.body.statements, isBuilder: true))
        if let alternative = source.elseBody {
            switch alternative {
            case .ifExpr(let nested): result.elseBody = .ifExpr(rewriteIf(nested))
            case .codeBlock(var block):
                block.statements = CodeBlockItemListSyntax(statements(block.statements, isBuilder: true))
                result.elseBody = .codeBlock(block)
            }
        }
        return result
    }

    func rewriteSwitch(_ source: SwitchExprSyntax) -> SwitchExprSyntax
    {
        var result = source
        result.cases = SwitchCaseListSyntax(source.cases.map { element in
            switch element {
            case .switchCase(var branch):
                branch.statements = CodeBlockItemListSyntax(statements(branch.statements, isBuilder: true))
                return .switchCase(branch)
            case .ifConfigDecl(var conditional):
                conditional.clauses = IfConfigClauseListSyntax(conditional.clauses.map { clause in
                    var result = clause
                    if case .switchCases(let cases) = clause.elements {
                        var nested = source
                        nested.cases = cases
                        result.elements = .switchCases(rewriteSwitch(nested).cases)
                    }
                    return result
                })
                return .ifConfigDecl(conditional)
            }
        })
        return result
    }

    func rewriteConditional(_ source: IfConfigDeclSyntax) -> IfConfigDeclSyntax
    {
        var result = source
        result.clauses = IfConfigClauseListSyntax(source.clauses.map { clause in
            var result = clause
            if case .statements(let items) = clause.elements {
                result.elements = .statements(CodeBlockItemListSyntax(statements(items, isBuilder: true)))
            }
            return result
        })
        return result
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax { ExprSyntax(node) }
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax { DeclSyntax(node) }
    override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax { DeclSyntax(node) }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax
    {
        var call = super.visit(node).cast(FunctionCallExprSyntax.self)
        let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
            ?? call.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        guard let name else { return ExprSyntax(call) }

        // A multiple-trailing-closure presentation call can put onDismiss
        // first and content second. Menu can similarly end in primaryAction
        // when both of its builder arguments are already supplied.
        let primaryIsAction = (["sheet", "fullScreenCover"].contains(name)
            && call.additionalTrailingClosures.contains { $0.label.text == "content" })
            || (name == "Menu" && call.arguments.contains { $0.label?.text == "content" }
                && call.arguments.contains { $0.label?.text == "label" })
        if Self.builders.contains(name), !primaryIsAction {
            if let closure = call.trailingClosure { call.trailingClosure = builderClosure(closure) }
        }
        else if name == "Button", call.arguments.contains(where: { $0.label?.text == "action" }), let closure = call.trailingClosure {
            call.trailingClosure = builderClosure(closure)
        }

        if Self.builders.contains(name) || name == "Button" {
            call.arguments = LabeledExprListSyntax(call.arguments.map { argument in
                var result = argument
                if Self.builderLabels.contains(argument.label?.text ?? ""), let closure = argument.expression.as(ClosureExprSyntax.self) {
                    result.expression = ExprSyntax(builderClosure(closure))
                }
                return result
            })
            call.additionalTrailingClosures = MultipleTrailingClosureElementListSyntax(call.additionalTrailingClosures.map { element in
                var result = element
                if Self.builderLabels.contains(element.label.text) { result.closure = builderClosure(element.closure) }
                return result
            })
        }
        return ExprSyntax(call)
    }

    func builderClosure(_ source: ClosureExprSyntax) -> ClosureExprSyntax
    {
        var result = source
        result.statements = CodeBlockItemListSyntax(statements(source.statements, isBuilder: true))
        return result
    }

    static let builders: Set<String> = [
        "VStack", "HStack", "ZStack", "LazyVStack", "LazyHStack", "Group",
        "ForEach", "ScrollView", "ScrollViewReader", "GeometryReader",
        "List", "Form", "Section", "Grid", "GridRow", "LazyVGrid", "LazyHGrid",
        "NavigationStack", "NavigationSplitView", "ViewThatFits", "TimelineView",
        "Menu", "DisclosureGroup", "Toggle", "Picker",
        // Slider's unlabeled trailing closure may be onEditingChanged.
        "overlay", "background", "mask", "safeAreaInset", "safeAreaBar",
        "sheet", "fullScreenCover", "popover", "navigationDestination",
    ]

    static let builderLabels: Set<String> = [
        "content", "label", "header", "footer", "sidebar", "detail", "root",
        "minimumValueLabel", "maximumValueLabel",
    ]
}
#endif
