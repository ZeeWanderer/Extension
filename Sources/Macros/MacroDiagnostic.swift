//
//  MacroDiagnostic.swift
//  Extension
//
//  Created by zee wanderer on 26.02.2025.
//

#if canImport(SwiftSyntax) && canImport(SwiftSyntaxMacros) && canImport(SwiftSyntaxBuilder)
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics


enum MacroDiagnostic<M: MacroDiagnosticProtocol>: Hashable, DiagnosticMessage {
    case error(String)
    case onlyApplicableToEnum
    case onlyApplicableToExtension
    case onlyApplicableToClass
    case onlyApplicableToStruct
    case onlyApplicableToProtocol
    case onlyApplicableToFunction
    case argumentMissing(String)
    
    var severity: DiagnosticSeverity { .error }
    var message: String {
        switch self {
        case .error(let msg):
            "@\(M.userFacingName): \(msg)"
        case .onlyApplicableToEnum:
            "@\(M.userFacingName) can only be applied to an enum."
        case .onlyApplicableToClass:
            "@\(M.userFacingName) can only be applied to a class."
        case .onlyApplicableToStruct:
            "@\(M.userFacingName) can only be applied to a struct."
        case .onlyApplicableToProtocol:
            "@\(M.userFacingName) can only be applied to a protocol."
        case .onlyApplicableToExtension:
            "@\(M.userFacingName) can only be applied to an extension."
        case .onlyApplicableToFunction:
            "@\(M.userFacingName) can only be applied to a function."
        case .argumentMissing(let argName):
            "@\(M.userFacingName) expects \(argName) to be present"
        }
    }
    var diagnosticID: MessageID {
        MessageID(domain: "\(M.self)", id: "\(self.hashValue)")
    }
}

#endif
