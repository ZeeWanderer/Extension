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
    @available(*, deprecated)
    nonisolated static var name: String { get }
}

public extension LogSubsystemProtocol
{
    @inlinable nonisolated static var bundle: String { Bundle.main.bundleIdentifier ?? "unknown" }
    @available(*, deprecated)
    @inlinable nonisolated static var name: String { class_ }
    @inlinable nonisolated static var subsystem: String { "\(bundle).\(class_)" }
    @available(*, deprecated, renamed: "logScope")
    @inlinable nonisolated static var messagePrefix: String { logScope }
    @inlinable nonisolated static var logScope: String { "[\(class_)]" }
    @inlinable nonisolated static func makeLogger() -> Logger { Logger(subsystem: subsystem, category: class_) }
}

internal extension LogSubsystemProtocol
{
    @usableFromInline nonisolated static var class_: String { "\(Self.self)" }
}
