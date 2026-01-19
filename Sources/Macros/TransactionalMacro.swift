//
//  TransactionalMacro.swift
//  Extension
//
//  Created by zeewanderer on 09.07.2025.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct TransactionalMacro: MacroDiagnosticProtocol {}

extension TransactionalMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToFunction))
            return []
        }

        let funcName = function.name.trimmed.text
        let originalName = "__original_\(funcName)"
        let (ctxExprOpt, ctxIsOptional) = extractModelContext(from: function, node: node)
        let ctxExpr = ctxExprOpt ?? ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("modelContext")))
        let returnType = function.signature.returnClause?.type
        let hasReturn = returnType != nil
        let isThrowing = function.signature.effectSpecifiers?.throwsClause != nil
        let retvalExpr = node.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "retval" })?.expression

        if hasReturn && retvalExpr == nil && !returnType!.is(OptionalTypeSyntax.self) {
            context.diagnose(Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("retval")))
            return []
        }

        let originalFunction = buildOriginalFunction(function, originalName)
        let transactionalCall = buildTransactionalCall(
            function: function,
            originalName: originalName,
            ctxExpr: ctxExpr,
            ctxIsOptional: ctxIsOptional,
            hasReturn: hasReturn,
            isThrowing: isThrowing,
            returnType: returnType,
            retvalExpr: retvalExpr
        )

        return [
            CodeBlockItemSyntax(item: .decl(DeclSyntax(originalFunction))),
            CodeBlockItemSyntax(item: .expr(transactionalCall))
        ]
    }

    private static func extractModelContext(from function: FunctionDeclSyntax, node: AttributeSyntax) -> (ExprSyntax?, Bool) {
        if let args = node.arguments?.as(LabeledExprListSyntax.self) {
            if let ctxArg = args.first(where: { $0.label?.text == "ctx" }) {
                let ctxExpr = ctxArg.expression
                let isOptional = ctxExpr.as(OptionalChainingExprSyntax.self) != nil
                return (ctxExpr, isOptional)
            } else if let keyPathArg = args.first(where: { $0.label?.text == "keyPath" }) {
                let ctxExpr = keyPathArg.expression
                if let keyPathExpr = ctxExpr.as(KeyPathExprSyntax.self) {
                    let selfExpr = DeclReferenceExprSyntax(baseName: .keyword(.self))
                    let subscriptExpr = SubscriptCallExprSyntax(
                        calledExpression: selfExpr,
                        leftSquare: .leftSquareToken(),
                        arguments: LabeledExprListSyntax {
                            LabeledExprSyntax(label: .identifier("keyPath"), colon: .colonToken(), expression: ExprSyntax(keyPathExpr))
                        },
                        rightSquare: .rightSquareToken()
                    )
                    
                    let postfixQuestionMark = keyPathExpr.components.last?.component.as(KeyPathOptionalComponentSyntax.self)?.questionOrExclamationMark.trimmed
                    let isOptional = postfixQuestionMark != nil
                    return (ExprSyntax(subscriptExpr), isOptional)
                }
            }
        }

        for param in function.signature.parameterClause.parameters {
            if let typeId = param.type.as(IdentifierTypeSyntax.self), typeId.name.trimmed.text == "ModelContext" {
                let name = param.secondName?.trimmed ?? param.firstName.trimmed
                return (ExprSyntax(DeclReferenceExprSyntax(baseName: name)), false)
            } else if let opt = param.type.as(OptionalTypeSyntax.self),
                      let wrapped = opt.wrappedType.as(IdentifierTypeSyntax.self), wrapped.name.trimmed.text == "ModelContext" {
                let name = param.secondName?.trimmed ?? param.firstName.trimmed
                return (ExprSyntax(DeclReferenceExprSyntax(baseName: name)), true)
            }
        }

        return (nil, false)
    }

    private static func buildOriginalFunction(_ function: FunctionDeclSyntax, _ originalName: String) -> FunctionDeclSyntax {
        var originalFunction = function
        originalFunction.name = .identifier(originalName)
        originalFunction.attributes = function.attributes.filter { $0.as(AttributeSyntax.self)?.attributeName.trimmed.description != "Transactional" }
        originalFunction.modifiers = DeclModifierListSyntax([])
        return originalFunction
    }

    private static func buildTransactionalCall(
        function: FunctionDeclSyntax,
        originalName: String,
        ctxExpr: ExprSyntax,
        ctxIsOptional: Bool,
        hasReturn: Bool,
        isThrowing: Bool,
        returnType: TypeSyntax?,
        retvalExpr: ExprSyntax?
    ) -> ExprSyntax {
        let ctxExprInit = ctxExpr
        var ctxExpr = ctxExpr
        
        let callArgs = LabeledExprListSyntax {
            function.signature.parameterClause.parameters.map { param in
                let paramName = param.secondName ?? param.firstName
                let label = param.firstName.text == "_" ? nil : param.firstName.text
                return LabeledExprSyntax(
                    label: label.map { .identifier($0) },
                    colon: label != nil ? .colonToken() : nil,
                    expression: DeclReferenceExprSyntax(baseName: paramName.trimmed)
                )
            }
        }

        let originalCallExpr = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier(originalName)),
            leftParen: .leftParenToken(),
            arguments: callArgs,
            rightParen: .rightParenToken()
        )
        let tryOriginal = isThrowing ? ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: originalCallExpr)) : ExprSyntax(originalCallExpr)

        if ctxIsOptional {
            ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("context")))
            let unwrapCondition = OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(.let),
                pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("context"))),
                initializer: InitializerClauseSyntax(value: ctxExprInit)
            )
            let transactionIf = makeTransactionIf(hasReturn: hasReturn, isThrowing: isThrowing, returnType: returnType, ctxExpr: ctxExpr, retvalExpr: retvalExpr, tryCall: tryOriginal)
            let ifExpr = IfExprSyntax(
                ifKeyword: .keyword(.if),
                conditions: ConditionElementListSyntax([ConditionElementSyntax(condition: .optionalBinding(unwrapCondition))]),
                body: CodeBlockSyntax(statements: CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(transactionIf)) }),
                elseKeyword: .keyword(.else),
                elseBody: .codeBlock(CodeBlockSyntax(statements: hasReturn
                    ? CodeBlockItemListSyntax { ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: tryOriginal) }
                    : CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryOriginal)) }
                ))
            )
            return ExprSyntax(ifExpr)
        } else {
            return makeTransactionIf(hasReturn: hasReturn, isThrowing: isThrowing, returnType: returnType, ctxExpr: ctxExpr, retvalExpr: retvalExpr, tryCall: tryOriginal)
        }
    }

    private static func makeTransactionIf(
        hasReturn: Bool,
        isThrowing: Bool,
        returnType: TypeSyntax?,
        ctxExpr: ExprSyntax,
        retvalExpr: ExprSyntax?,
        tryCall: ExprSyntax
    ) -> ExprSyntax {
        let condition = ConditionElementSyntax(condition: .expression(
            ExprSyntax(MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")), name: .identifier("isActive")))
        ))

        let ifBranch = hasReturn
            ? CodeBlockItemListSyntax { ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: tryCall) }
            : CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryCall)) }

        let elseBranch = hasReturn
            ? CodeBlockItemListSyntax {
                ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: buildElseWithReturn(ctxExpr: ctxExpr, retvalInit: retvalExpr ?? ExprSyntax(NilLiteralExprSyntax()), tryCall: tryCall, returnType: returnType!, isThrowing: isThrowing))
            }
            : CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(buildElseNoReturn(ctxExpr: ctxExpr, tryCall: tryCall, isThrowing: isThrowing))) }

        return ExprSyntax(IfExprSyntax(
            ifKeyword: .keyword(.if),
            conditions: ConditionElementListSyntax([condition]),
            body: CodeBlockSyntax(statements: ifBranch),
            elseKeyword: .keyword(.else),
            elseBody: .codeBlock(CodeBlockSyntax(statements: elseBranch))
        ))
    }

    private static func buildElseWithReturn(ctxExpr: ExprSyntax, retvalInit: ExprSyntax, tryCall: ExprSyntax, returnType: TypeSyntax, isThrowing: Bool) -> ExprSyntax {
        let transactionCall = FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(base: ctxExpr, name: .identifier("transaction")),
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken(),
            trailingClosure: ClosureExprSyntax(statements: CodeBlockItemListSyntax {
                CodeBlockItemSyntax(item: .expr(ExprSyntax(SequenceExprSyntax(elements: ExprListSyntax([
                    PatternExprSyntax(pattern: IdentifierPatternSyntax(identifier: .identifier("retval"))),
                    AssignmentExprSyntax(equal: .equalToken()),
                    tryCall
                ])))))
            })
        )
        let tryTransaction = isThrowing
            ? ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: transactionCall))
            : ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), questionOrExclamationMark: .postfixQuestionMarkToken(), expression: transactionCall))

        return ExprSyntax(FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(base: MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")), name: .identifier("$isActive")), name: .identifier("withValue")),
            leftParen: .leftParenToken(),
            arguments: [LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))],
            rightParen: .rightParenToken(),
            trailingClosure: ClosureExprSyntax(statements: CodeBlockItemListSyntax {
                VariableDeclSyntax(bindingSpecifier: .keyword(.var), bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(pattern: IdentifierPatternSyntax(identifier: .identifier("retval")), typeAnnotation: TypeAnnotationSyntax(type: returnType), initializer: InitializerClauseSyntax(value: retvalInit))
                })
                CodeBlockItemSyntax(item: .expr(tryTransaction))
                ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: DeclReferenceExprSyntax(baseName: .identifier("retval")))
            })
        ))
    }

    private static func buildElseNoReturn(ctxExpr: ExprSyntax, tryCall: ExprSyntax, isThrowing: Bool) -> ExprSyntax {
        let transactionCall = FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(base: ctxExpr, name: .identifier("transaction")),
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken(),
            trailingClosure: ClosureExprSyntax(statements: CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryCall)) })
        )
        let tryTransaction = isThrowing
            ? ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: transactionCall))
            : ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), questionOrExclamationMark: .postfixQuestionMarkToken(), expression: transactionCall))

        return ExprSyntax(FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(base: MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")), name: .identifier("$isActive")), name: .identifier("withValue")),
            leftParen: .leftParenToken(),
            arguments: [LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))],
            rightParen: .rightParenToken(),
            trailingClosure: ClosureExprSyntax(statements: CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryTransaction)) })
        ))
    }
}

#endif
