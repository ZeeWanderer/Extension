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
    @inlinable nonisolated static var messagePrefix: String { "[\(Subsystem.name)::\(category)]" }
    @inlinable nonisolated static func makeLogger() -> Logger { Logger(subsystem: Subsystem.subsystem, category: category) }
}
