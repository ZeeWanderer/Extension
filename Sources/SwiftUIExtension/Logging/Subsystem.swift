//
//  Subsystem.swift
//  Extension
//
//  Created by zeewanderer on 27.01.2026.
//

import os
import osExtension

public enum SwiftUIExtension: LogSubsystemProtocol
{
    nonisolated public static let logger = makeLogger()
    nonisolated public static let signposter = makeSignposter()
}
