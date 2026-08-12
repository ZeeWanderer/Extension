//
//  RouterViewRegistrationConflictPolicy.swift
//  Extension
//
//  Created by zeewanderer on 12.08.2026.
//

/// Controls how a registered router handles duplicate flat destinations.
public enum RouterViewRegistrationConflictPolicy: Hashable, Sendable
{
    case precondition
    case keepFirst
    case keepLast
}
