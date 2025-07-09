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
            let diag = Diagnostic(
                node: node,
                message: MacroDiagnostic<Self>.error("@Transactional can only be applied to functions")
            )
            context.diagnose(diag)
            return []
        }
        
        let isThrowing = function.signature.effectSpecifiers?.throwsClause != nil
        let returnType = function.signature.returnClause?.type
        let hasReturn = returnType != nil
        let funcName = function.name.trimmed
        
        var ctxExpr: ExprSyntax?
        
        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for argument in arguments {
                if argument.label?.text == "ctx" {
                    ctxExpr = argument.expression
                    break
                }
            }
        }
        
        if ctxExpr == nil {
            for param in function.signature.parameterClause.parameters {
                if let type = param.type.as(IdentifierTypeSyntax.self),
                   type.name.trimmed.text == "ModelContext" {
                    ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: param.firstName.trimmed))
                    break
                }
            }
        }
        
        if ctxExpr == nil {
            ctxExpr = ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("modelContext")))
        }
        
        let originalFuncName = "__original_\(funcName)"
        var originalFunction = function
        originalFunction.name = .identifier(originalFuncName)
        originalFunction.attributes = function.attributes.filter({ attr in
            attr.as(AttributeSyntax.self)?.attributeName.trimmed.description != "Transactional"
        })
        
        var callArguments = LabeledExprListSyntax()
        for param in function.signature.parameterClause.parameters {
            let paramName = param.secondName ?? param.firstName
            let label = param.firstName.text == "_" ? nil : param.firstName.text
            
            callArguments.append(LabeledExprSyntax(
                label: label.map { .identifier($0) },
                colon: label != nil ? .colonToken() : nil,
                expression: DeclReferenceExprSyntax(baseName: paramName.trimmed),
                trailingComma: param.trailingComma
            ))
        }
        
        let originalCall = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier(originalFuncName)),
            leftParen: .leftParenToken(),
            arguments: callArguments,
            rightParen: .rightParenToken()
        )
        
        let tryOriginalCall: ExprSyntax = if isThrowing {
            ExprSyntax(TryExprSyntax(tryKeyword: .keyword(.try), expression: originalCall))
        } else {
            ExprSyntax(originalCall)
        }
        
        let condition = ConditionElementSyntax(
            condition: .expression(
                ExprSyntax(
                    MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: .identifier("isActive"))
                    )
                )
            )
        )
        
        let ifBranch: CodeBlockItemListSyntax = if hasReturn {
            CodeBlockItemListSyntax {
                ReturnStmtSyntax(
                    returnKeyword: .keyword(.return),
                    expression: tryOriginalCall
                )
            }
        } else {
            CodeBlockItemListSyntax {
                CodeBlockItemSyntax(item: .expr(tryOriginalCall))
            }
        }
        
        let elseBranch: CodeBlockItemListSyntax
        if hasReturn {
            elseBranch = CodeBlockItemListSyntax {
                ReturnStmtSyntax(
                    returnKeyword: .keyword(.return),
                    expression: ExprSyntax(
                        FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                                period: .periodToken(),
                                declName: DeclReferenceExprSyntax(baseName: .identifier("$isActive"))
                            ),
                            leftParen: .leftParenToken(),
                            arguments: [
                                LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))
                            ],
                            rightParen: .rightParenToken(),
                            trailingClosure: ClosureExprSyntax(
                                leftBrace: .leftBraceToken(),
                                statements: CodeBlockItemListSyntax {
                                    VariableDeclSyntax(
                                        bindingSpecifier: .keyword(.let),
                                        bindings: PatternBindingListSyntax {
                                            PatternBindingSyntax(
                                                pattern: IdentifierPatternSyntax(identifier: .identifier("retval")),
                                                typeAnnotation: TypeAnnotationSyntax(
                                                    colon: .colonToken(),
                                                    type: returnType!
                                                )
                                            )
                                        }
                                    )
                                    
                                    let transactionCall = FunctionCallExprSyntax(
                                        calledExpression: MemberAccessExprSyntax(
                                            base: ctxExpr!,
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
                                                    SequenceExprSyntax(
                                                        elements: ExprListSyntax {
                                                            PatternExprSyntax(
                                                                pattern: IdentifierPatternSyntax(
                                                                    identifier: .identifier("retval"))
                                                            )
                                                            AssignmentExprSyntax(equal: .equalToken())
                                                            tryOriginalCall
                                                        }
                                                    )
                                                ))
                                                )
                                            }
                                        )
                                    )
                                    
                                    
                                    if isThrowing {
                                        CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                            TryExprSyntax(
                                                tryKeyword: .keyword(.try),
                                                expression: transactionCall
                                            )
                                        )))
                                    } else {
                                        CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                            TryExprSyntax(
                                                tryKeyword: .keyword(.try),
                                                questionOrExclamationMark: .postfixQuestionMarkToken(),
                                                expression: transactionCall
                                            )
                                        )))
                                    }
                                    
                                    ReturnStmtSyntax(
                                        returnKeyword: .keyword(.return),
                                        expression: DeclReferenceExprSyntax(baseName: .identifier("retval"))
                                    )
                                },
                                rightBrace: .rightBraceToken()
                            )
                        )
                    )
                )
            }
        } else {
            elseBranch = CodeBlockItemListSyntax {
                CodeBlockItemSyntax(item: .expr(ExprSyntax(
                    FunctionCallExprSyntax(
                        calledExpression: MemberAccessExprSyntax(
                            base: DeclReferenceExprSyntax(baseName: .identifier("TransactionContext")),
                            period: .periodToken(),
                            declName: DeclReferenceExprSyntax(baseName: .identifier("$isActive"))
                        ),
                        leftParen: .leftParenToken(),
                        arguments: [
                            LabeledExprSyntax(expression: BooleanLiteralExprSyntax(true))
                        ],
                        rightParen: .rightParenToken(),
                        trailingClosure: ClosureExprSyntax(
                            leftBrace: .leftBraceToken(),
                            statements: CodeBlockItemListSyntax {
                                let transactionCall = FunctionCallExprSyntax(
                                    calledExpression: MemberAccessExprSyntax(
                                        base: ctxExpr!,
                                        period: .periodToken(),
                                        declName: DeclReferenceExprSyntax(baseName: .identifier("transaction"))
                                    ),
                                    leftParen: .leftParenToken(),
                                    arguments: [],
                                    rightParen: .rightParenToken(),
                                    trailingClosure: ClosureExprSyntax(
                                        leftBrace: .leftBraceToken(),
                                        statements: CodeBlockItemListSyntax {
                                            CodeBlockItemSyntax(item: .expr(tryOriginalCall))
                                        },
                                        rightBrace: .rightBraceToken()
                                    )
                                )
                                
                                if isThrowing {
                                    CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                        TryExprSyntax(
                                            tryKeyword: .keyword(.try),
                                            expression: transactionCall
                                        )
                                    )))
                                } else {
                                    CodeBlockItemSyntax(item: .expr(ExprSyntax(
                                        TryExprSyntax(
                                            tryKeyword: .keyword(.try),
                                            questionOrExclamationMark: .postfixQuestionMarkToken(),
                                            expression: transactionCall
                                        )
                                    )))
                                }
                            },
                            rightBrace: .rightBraceToken()
                        )
                    )
                )))
            }
        }
        
        let ifStmt = IfExprSyntax(
            ifKeyword: .keyword(.if),
            conditions: ConditionElementListSyntax([condition]),
            body: CodeBlockSyntax(
                leftBrace: .leftBraceToken(),
                statements: ifBranch,
                rightBrace: .rightBraceToken()
            ),
            elseKeyword: .keyword(.else),
            elseBody: .codeBlock(
                CodeBlockSyntax(
                    leftBrace: .leftBraceToken(),
                    statements: elseBranch,
                    rightBrace: .rightBraceToken()
                )
            )
        )
        
        return [
            CodeBlockItemSyntax(item: .decl(DeclSyntax(originalFunction))),
            CodeBlockItemSyntax(item: .expr(ExprSyntax(ifStmt)))
        ]
    }
}
