//
//  LogSubsystemProtocol.swift
//
//
//  Created by zee wanderer on 11.02.2025.
//

import Foundation
import os

/// A helper protocol for establishing logging
///
/// default vars should be declared like these
/// ```
/// nonisolated static let logger = makeLogger()
/// nonisolated static let signposter = makeSignposter()
/// ```
/// `logScope` adds scope to message
/// ```
/// Self.logger.log("\(Self.logScope, privacy: .public)")
/// ```
public protocol LogSubsystemProtocol: LogProtocol
{
    nonisolated static var bundle: String { get }
    nonisolated static var subsystem: String { get }
}

public extension LogSubsystemProtocol
{
    @inlinable nonisolated static var bundle: String { Bundle.main.bundleIdentifier ?? "unknown" }
    @inlinable nonisolated static var subsystem: String { "\(bundle).\(p_className)" }
    @inlinable nonisolated static var logScope: String { "[\(p_className)]" }
    @inlinable nonisolated static func makeLogger() -> Logger { Logger(subsystem: subsystem, category: p_className) }
}

internal extension LogSubsystemProtocol
{
    @usableFromInline nonisolated static var p_className: String { "\(Self.self)" }
}
