//
//  LogProtocol.swift
//  
//
//  Created by zee wanderer on 27.02.2025.
//

import os

public protocol LogProtocol
{
    nonisolated static var logger: Logger { get }
    nonisolated static var signposter: OSSignposter { get }
    nonisolated static func makeLogger() -> Logger
    nonisolated static func makeSignposter() -> OSSignposter
    @available(*, deprecated, renamed: "logScope")
    nonisolated static var messagePrefix: String { get }
    nonisolated static var logScope: String { get }
}

public extension LogProtocol
{
    @inlinable nonisolated static func makeSignposter() -> OSSignposter
    {
        OSSignposter(logger: Self.logger)
    }
}
