//
//  P_MacroDiagnosticProtocol.swift
//  Extension
//
//  Created by zee wanderer on 26.02.2025.
//

internal protocol P_MacroDiagnosticProtocol {
    static var moduleName: String { get }
    static var userFacingName: String { get }
}

extension P_MacroDiagnosticProtocol {
    static var moduleName: String { "Macros" }
    static var userFacingName: String {
        "\(Self.self)".replacingOccurrences(of: "Macro", with: "")
    }
}
