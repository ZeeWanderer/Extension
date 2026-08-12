//
//  BinaryRepresentable.swift
//
//
//  Created by zeewanderer on 20.05.2024.
//

import Foundation

// MARK: - BinaryRepresentable

/// Streamlines same-type transformation to and from native bytes.
///
/// `BinaryRepresentable` is intentionally a native-memory representation, not
/// a portable serialization format. The producing and consuming code is
/// responsible for using the same type and a compatible layout.
///
/// - Warning: Ensure that a conforming type is `BitwiseCopyable`. Prefer
///   ``SafeBinaryRepresentable`` for custom types so the compiler verifies that
///   requirement.
public protocol BinaryRepresentable
{
    init(data: Data)

    /// Loads a value when the buffer contains enough bytes for the requested
    /// type. This does not validate semantic invariants of the loaded value.
    init?(validating data: Data)

    /// The value's native-memory representation.
    var data: Data { get }
}

/// A `BinaryRepresentable` type whose native bytes can be copied directly.
public typealias SafeBinaryRepresentable = BinaryRepresentable & BitwiseCopyable

public extension BinaryRepresentable
{
    @inlinable
    init(data: Data)
    {
        self = data.load(as: Self.self)
    }

    @inlinable
    init?(validating data: Data)
    {
        guard let value = data.saferLoad(as: Self.self) else { return nil }
        self = value
    }

    @inlinable
    var data: Data
    {
        withUnsafeBytes(of: self) { Data($0) }
    }
}
