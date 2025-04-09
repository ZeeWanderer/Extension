//
//  LogSubsystemCategoryProtocol.swift
//  
//
//  Created by zee wanderer on 12.02.2025.
//

import os

public protocol LogSubsystemCategoryProtocol<Subsystem>: LogProtocol
{
    associatedtype Subsystem: LogSubsystemProtocol
    nonisolated static var category: String { get }
}

public extension LogSubsystemCategoryProtocol
{
    @inlinable nonisolated static var category: String { "\(Self.self)" }
    @available(*, deprecated, renamed: "logScope")
    @inlinable nonisolated static var messagePrefix: String { logScope }
    @inlinable nonisolated static var logScope: String { "[\(Subsystem.class_)::\(category)]" }
    @inlinable nonisolated static func makeLogger() -> Logger { Logger(subsystem: Subsystem.subsystem, category: category) }
}
