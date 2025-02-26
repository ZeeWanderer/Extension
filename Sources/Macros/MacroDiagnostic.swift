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


enum MacroDiagnostic<M: MacroDiagnosticProtocol>: String, DiagnosticMessage {
  case onlyApplicableToEnum
  
  var severity: DiagnosticSeverity { .error }
  var message: String {
      switch self {
      case .onlyApplicableToEnum:
          "@\(M.userFacingName) can only be applied to an enum."
      }
  }
  var diagnosticID: MessageID {
      MessageID(domain: "\(M.self)", id: rawValue)
  }
}
