//
//  Macros.swift
//  Extension
//
//  Created by zee wanderer on 29.10.2024.
//

import SwiftUI
import SwiftData

/// A macro that generates encapsulated flat version of the enum by excluding associated values
/// and provides mapping from original to flat enum for case identification purposes.
@attached(member, names: arbitrary)
public macro FlatEnum() =
#externalMacro(
    module: "Macros", type: "FlatEnumMacro"
)

@attached(member, names: arbitrary)
public macro ModelSnapshot() =
#externalMacro(
    module: "Macros", type: "ModelSnapshotMacro"
)

@attached(peer)
public macro SnapshotIgnore() = #externalMacro(module: "Macros", type: "SnapshotIgnoreMacro")

@attached(peer)
public macro SnapshotShallow() = #externalMacro(module: "Macros", type: "SnapshotShallowMacro")

@attached(extension, names: arbitrary)
public macro CustomStringConvertibleEnum() =
#externalMacro(
    module: "Macros", type: "CustomStringConvertibleEnumMacro"
)

@attached(peer, names: suffixed(Actor))
public macro ActorProtocol() =
#externalMacro(
    module: "Macros", type: "ActorProtocolMacro"
)

@attached(extension, names: arbitrary)
public macro ActorProtocolExtension(name: String) =
#externalMacro(
    module: "Macros", type: "ActorProtocolExtensionMacro"
)

@attached(peer)
public macro ActorProtocolIgnore() = #externalMacro(module: "Macros", type: "ActorProtocolIgnoreMacro")

@attached(body)
public macro Transactional(ctx: ModelContext? = nil, retval: Any? = nil) = #externalMacro(
    module: "Macros", type: "TransactionalMacro"
)

@attached(body)
public macro Transactional<R>(keyPath: any KeyPath<R, ModelContext> & Sendable, retval: Any? = nil) = #externalMacro(
    module: "Macros", type: "TransactionalMacro"
)

@attached(body)
public macro Transactional<R>(keyPath: any KeyPath<R, ModelContext?> & Sendable, retval: Any? = nil) = #externalMacro(
    module: "Macros", type: "TransactionalMacro"
)
