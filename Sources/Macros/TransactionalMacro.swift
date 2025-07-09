//
//  TransactionalMacro.swift
//  Extension
//
//  Created by zeewanderer on 09.07.2025.
//

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
            let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.onlyApplicableToFunction)
            context.diagnose(diag)
            return []
        }

        let isThrowing = function.signature.effectSpecifiers?.throwsClause != nil
        let returnType = function.signature.returnClause?.type
        let hasReturn = returnType != nil
        let funcName = function.name.trimmed.text

        var ctxExpr: ExprSyntax?
        var ctxIsOptional = false
        var retvalExpr: ExprSyntax?
        if let args = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in args {
                if arg.label?.text == "ctx" {
                    ctxExpr = arg.expression
                } else if arg.label?.text == "retval" {
                    retvalExpr = arg.expression
                }
            }
        }
        if ctxExpr == nil {
            for param in function.signature.parameterClause.parameters {
                if let typeId = param.type.as(IdentifierTypeSyntax.self), typeId.name.trimmed.text == "ModelContext" {
                    let name = param.secondName?.trimmed ?? param.firstName.trimmed
                    ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: name))
                } else if let opt = param.type.as(OptionalTypeSyntax.self),
                          let wrapped = opt.wrappedType.as(IdentifierTypeSyntax.self), wrapped.name.trimmed.text == "ModelContext" {
                    let name = param.secondName?.trimmed ?? param.firstName.trimmed
                    ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: name))
                    ctxIsOptional = true
                }
                if ctxExpr != nil { break }
            }
        }
        if ctxExpr == nil {
            ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("modelContext")))
        }

        if hasReturn {
            let isOptionalReturn = returnType!.is(OptionalTypeSyntax.self)
            if retvalExpr == nil && !isOptionalReturn {
                let diag = Diagnostic(node: node, message: MacroDiagnostic<Self>.argumentMissing("retval"))
                context.diagnose(diag)
                return []
            }
        }

        let originalName = "__original_\(funcName)"
        var originalFunction = function
        originalFunction.name = .identifier(originalName)
        originalFunction.attributes = function.attributes.filter { attr in
            attr.as(AttributeSyntax.self)?.attributeName.trimmed.description != "Transactional"
        }
        originalFunction.modifiers = DeclModifierListSyntax([])

        var callArgs = LabeledExprListSyntax()
        for param in function.signature.parameterClause.parameters {
            let paramName = param.secondName ?? param.firstName
            let label = param.firstName.text == "_" ? nil : param.firstName.text
            callArgs.append(LabeledExprSyntax(
                label: label.map { .identifier($0) },
                colon: label != nil ? .colonToken() : nil,
                expression: DeclReferenceExprSyntax(baseName: paramName.trimmed),
                trailingComma: param.trailingComma
            ))
        }

        let originalCallExpr = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier(originalName)),
            leftParen: .leftParenToken(),
            arguments: callArgs,
            rightParen: .rightParenToken()
        )
        let tryOriginal = isThrowing
            ? ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: originalCallExpr))
            : ExprSyntax(originalCallExpr)

        let transactionIf = makeTransactionIf(
            hasReturn: hasReturn,
            isThrowing: isThrowing,
            returnType: returnType,
            ctxExpr: ctxExpr!,
            retvalExpr: retvalExpr,
            tryCall: tryOriginal
        )

        let finalExpr: ExprSyntax
        if ctxIsOptional {
            
            let unwrapCondition = OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(.let),
                pattern: PatternSyntax(IdentifierPatternSyntax(identifier: ctxExpr!.as(DeclReferenceExprSyntax.self)!.baseName))
            )
            let unwrappedIf = IfExprSyntax(
                ifKeyword: .keyword(.if),
                conditions: ConditionElementListSyntax([ConditionElementSyntax(condition: .optionalBinding(unwrapCondition))]),
                body: CodeBlockSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(transactionIf)) },
                    rightBrace: .rightBraceToken()
                ),
                elseKeyword: .keyword(.else),
                elseBody: .codeBlock(CodeBlockSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: hasReturn
                    ? CodeBlockItemListSyntax {
                        ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: tryOriginal)
                    }
                    : CodeBlockItemListSyntax {
                        CodeBlockItemSyntax(item: .expr(tryOriginal))
                    },
                    rightBrace: .rightBraceToken()
                ))
            )
            finalExpr = ExprSyntax(unwrappedIf)
        } else {
            finalExpr = transactionIf
        }

        return [
            CodeBlockItemSyntax(item: .decl(DeclSyntax(originalFunction))),
            CodeBlockItemSyntax(item: .expr(finalExpr))
        ]
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
            ExprSyntax(MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                period: .periodToken(),
                name: .identifier("isActive")
            ))
        ))

        let ifBranch = hasReturn
            ? CodeBlockItemListSyntax { ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: tryCall) }
            : CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryCall)) }

        let elseBranch = hasReturn
            ? CodeBlockItemListSyntax {
                let initExpr = retvalExpr ?? ExprSyntax(NilLiteralExprSyntax())
                ReturnStmtSyntax(
                    returnKeyword: .keyword(.return),
                    expression: buildElseWithReturn(ctxExpr: ctxExpr, retvalInit: initExpr, tryCall: tryCall, returnType: returnType!, isThrowing: isThrowing)
                )
            }
            : CodeBlockItemListSyntax {
                CodeBlockItemSyntax(item: .expr(buildElseNoReturn(ctxExpr: ctxExpr, tryCall: tryCall, isThrowing: isThrowing)))
            }

        let ifStmt = IfExprSyntax(
            ifKeyword: .keyword(.if),
            conditions: ConditionElementListSyntax([condition]),
            body: CodeBlockSyntax(leftBrace: .leftBraceToken(), statements: ifBranch, rightBrace: .rightBraceToken()),
            elseKeyword: .keyword(.else),
            elseBody: .codeBlock(CodeBlockSyntax(leftBrace: .leftBraceToken(), statements: elseBranch, rightBrace: .rightBraceToken()))
        )

        return ExprSyntax(ifStmt)
    }

    private static func buildElseWithReturn(
        ctxExpr: ExprSyntax,
        retvalInit: ExprSyntax,
        tryCall: ExprSyntax,
        returnType: TypeSyntax,
        isThrowing: Bool
    ) -> ExprSyntax {
        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                        period: .periodToken(),
                        name: .identifier("$isActive")
                    ),
                    period: .periodToken(),
                    name: .identifier("withValue")
                ),
                leftParen: .leftParenToken(),
                arguments: [LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))],
                rightParen: .rightParenToken(),
                trailingClosure: ClosureExprSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: CodeBlockItemListSyntax {
                        VariableDeclSyntax(
                            bindingSpecifier: .keyword(.var),
                            bindings: PatternBindingListSyntax {
                                PatternBindingSyntax(
                                    pattern: IdentifierPatternSyntax(identifier: .identifier("retval")),
                                    typeAnnotation: TypeAnnotationSyntax(colon: .colonToken(), type: returnType),
                                    initializer: InitializerClauseSyntax(equal: .equalToken(), value: retvalInit)
                                )
                            }
                        )
                        let transactionCall = FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                base: ctxExpr,
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(baseName: .identifier("transaction"))
                            ),
                            leftParen: .leftParenToken(),
                            arguments: [],
                            rightParen: .rightParenToken(),
                            trailingClosure: ClosureExprSyntax(
                                leftBrace: .leftBraceToken(),
                                statements: CodeBlockItemListSyntax {
                                    CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                        SequenceExprSyntax(elements: ExprListSyntax([
                                            PatternExprSyntax(pattern: IdentifierPatternSyntax(identifier: .identifier("retval"))),
                                            AssignmentExprSyntax(equal: .equalToken()),
                                            tryCall
                                        ]))
                                    )))
                                },
                                rightBrace: .rightBraceToken()
                            )
                        )
                        if isThrowing {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: transactionCall))))
                        } else {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), questionOrExclamationMark: .postfixQuestionMarkToken(), expression: transactionCall))))
                        }
                        ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: DeclReferenceExprSyntax(baseName: .identifier("retval")))
                    },
                    rightBrace: .rightBraceToken()
                )
            )
        )
    }

    private static func buildElseNoReturn(
        ctxExpr: ExprSyntax,
        tryCall: ExprSyntax,
        isThrowing: Bool
    ) -> ExprSyntax {
        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                        period: .periodToken(),
                        name: .identifier("$isActive")
                    ),
                    period: .periodToken(),
                    name: .identifier("withValue")
                ),
                leftParen: .leftParenToken(),
                arguments: [LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))],
                rightParen: .rightParenToken(),
                trailingClosure: ClosureExprSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: CodeBlockItemListSyntax {
                        let transactionCall = FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                base: ctxExpr,
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(baseName: .identifier("transaction"))
                            ),
                            leftParen: .leftParenToken(),
                            arguments: [],
                            rightParen: .rightParenToken(),
                            trailingClosure: ClosureExprSyntax(
                                leftBrace: .leftBraceToken(),
                                statements: CodeBlockItemListSyntax { CodeBlockItemSyntax(item: .expr(tryCall)) },
                                rightBrace: .rightBraceToken()
                            )
                        )
                        if isThrowing {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: transactionCall))))
                        } else {
                            CodeBlockItemSyntax(item: .expr(ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), questionOrExclamationMark: .postfixQuestionMarkToken(), expression: transactionCall))))
                        }
                    },
                    rightBrace: .rightBraceToken()
                )
            )
        )
    }
}
