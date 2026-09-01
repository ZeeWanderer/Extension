//
//  UnknownCaseCodable.swift
//  Extension
//
//  Created by zeewanderer on 01.09.2026.
//

import Foundation

/// A raw-representable value that maps unrecognized decoded values to a
/// fallback case.
///
/// Conform a raw-value enumeration and provide ``unknown`` when a service may
/// add values before the application is updated. A raw value that decodes
/// successfully but cannot initialize the conforming type becomes ``unknown``.
/// Known values retain ordinary `Codable` behavior.
///
/// ```swift
/// enum Status: String, UnknownCaseCodable
/// {
///     case active
///     case inactive
///     case unknown
/// }
/// ```
///
/// Decoding `"future-status"` as `Status` produces `.unknown`.
///
/// - Important: This fallback is intentionally lossy. Encoding the resulting
///   value writes `unknown.rawValue`, not the unrecognized value originally
///   received.
/// - Note: A value that cannot decode as `RawValue`, such as a number supplied
///   for a string-backed enumeration, still throws a decoding error.
public protocol UnknownCaseCodable: RawRepresentable, Codable
where RawValue: Codable
{
    /// The value used when a decoded raw value is not recognized.
    static var unknown: Self { get }
}

public extension UnknownCaseCodable
{
    @inlinable
    init(from decoder: any Decoder) throws
    {
        let rawValue = try RawValue(from: decoder)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    @inlinable
    func encode(to encoder: any Encoder) throws
    { try rawValue.encode(to: encoder) }
}
