//
//  LogSubsystemProtocol.swift
//  
//
//  Created by zee wanderer on 11.02.2025.
//

import Foundation
import os

/// A helper protocol for establishing logging
/// ```
/// nonisolated static let logger = makeLogger()
/// nonisolated static let signposter = makeSignposter()
/// ```
public protocol LogSubsystemProtocol: LogProtocol
{
    nonisolated static var bundle: String { get }
    nonisolated static var subsystem: String { get }
    nonisolated static var name: String { get }
}

public extension LogSubsystemProtocol
{
    @inlinable nonisolated static var bundle: String { Bundle.main.bundleIdentifier ?? "unknown" }
    @inlinable nonisolated static var name: String { "\(Self.self)" }
    @inlinable nonisolated static var subsystem: String { "\(bundle).\(name)" }
    @inlinable nonisolated static var messagePrefix: String { "[\(name)]" }
    @inlinable nonisolated static func makeLogger() -> Logger { Logger(subsystem: subsystem, category: name) }
}
