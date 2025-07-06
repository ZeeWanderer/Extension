//
//  MacroDiagnostic.swift
//  Extension
//
//  Created by zee wanderer on 26.02.2025.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics


enum MacroDiagnostic<M: MacroDiagnosticProtocol>: Hashable, DiagnosticMessage {
    case onlyApplicableToEnum
    case onlyApplicableToExtension
    case onlyApplicableToClass
    case onlyApplicableToProtocol
    case argumentMissing(String)
    
    var severity: DiagnosticSeverity { .error }
    var message: String {
        switch self {
        case .onlyApplicableToEnum:
            "@\(M.userFacingName) can only be applied to an enum."
        case .onlyApplicableToClass:
            "@\(M.userFacingName) can only be applied to a class."
        case .onlyApplicableToProtocol:
            "@\(M.userFacingName) can only be applied to a protocol."
        case .onlyApplicableToExtension:
            "@\(M.userFacingName) can only be applied to an extension."
        case .argumentMissing(let argName):
            "@\(M.userFacingName) extpects \(argName) to be present"
        }
    }
    var diagnosticID: MessageID {
        MessageID(domain: "\(M.self)", id: "\(self.hashValue)")
    }
}
