//
//  JSONCoding+RawRepresentable.swift
//
//
//  Created by zeewanderer on 04.09.2026.
//

import Foundation

public extension JSONCoding
{
    // MARK: - Synchronous decoding

    /// Decodes a JSON object whose keys are raw values of `Key`.
    func decode<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        from data: Data
    ) throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key.RawValue == RawValue,
          Value: Decodable,
          RawValue: Decodable, RawValue: Hashable
    {
        try decoder.decode(type, from: data)
    }

    /// Reads a file and decodes a JSON object whose keys are raw values of `Key`.
    func decode<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = []
    ) throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key.RawValue == RawValue,
          Value: Decodable,
          RawValue: Decodable, RawValue: Hashable
    {
        try decode(type, from: Data(contentsOf: url, options: options))
    }

    /// Loads and decodes a JSON resource whose object keys are raw values of `Key`.
    func decode<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = []
    ) throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key.RawValue == RawValue,
          Value: Decodable,
          RawValue: Decodable, RawValue: Hashable
    {
        let url = try p_resourceURL(
            named: name,
            withExtension: fileExtension,
            subdirectory: subdirectory,
            in: bundle
        )
        return try decode(type, contentsOf: url, options: options)
    }

    // MARK: - Explicit detached task decoding

    /// Starts decoding a JSON object with raw-representable keys in an explicitly detached task.
    func detachedDecodingTask<Key, Value, RawValue>(
        of type: [Key: Value].Type,
        from data: Data,
        priority: TaskPriority? = nil
    ) -> Task<[Key: Value], Error>
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable, RawValue: SendableMetatype
    {
        return Task.detached(priority: priority) { try await decodeAsync(type, from: data) }
    }

    /// Starts reading a file and decoding its raw-representable-keyed JSON object in a detached task.
    func detachedDecodingTask<Key, Value, RawValue>(
        of type: [Key: Value].Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) -> Task<[Key: Value], Error>
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable, RawValue: SendableMetatype
    {
        return Task.detached(priority: priority)
        {
            try await decodeAsync(type, contentsOf: url, options: options)
        }
    }

    /// Starts loading and decoding a raw-representable-keyed JSON resource in a detached task.
    func detachedDecodingTask<Key, Value, RawValue>(
        of type: [Key: Value].Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) -> Task<[Key: Value], Error>
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable, RawValue: SendableMetatype
    {
        return Task.detached(priority: priority)
        {
            try await decodeAsync(
                type,
                fromResource: name,
                withExtension: fileExtension,
                subdirectory: subdirectory,
                in: bundle,
                options: options
            )
        }
    }

    // MARK: - Awaited asynchronous decoding

    /// Decodes a JSON object with raw-representable keys in the caller's structured task.
    @concurrent
    func decodeAsync<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        from data: Data
    ) async throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable
    {
        try Task.checkCancellation()
        let value = try decoder.decode(type, from: data)
        try Task.checkCancellation()
        return value
    }

    /// Reads a file and decodes its raw-representable-keyed JSON object in the caller's structured task.
    @concurrent
    func decodeAsync<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = []
    ) async throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable
    {
        try Task.checkCancellation()
        let data = try Data(contentsOf: url, options: options)
        try Task.checkCancellation()
        let value = try decoder.decode(type, from: data)
        try Task.checkCancellation()
        return value
    }

    /// Loads and decodes a raw-representable-keyed JSON resource in the caller's structured task.
    @concurrent
    func decodeAsync<Key, Value, RawValue>(
        _ type: [Key: Value].Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = []
    ) async throws -> [Key: Value]
    where Key: RawRepresentable, Key: Decodable, Key: Sendable, Key.RawValue == RawValue,
          Value: Decodable, Value: Sendable,
          RawValue: Decodable, RawValue: Hashable
    {
        try Task.checkCancellation()
        let url = try p_resourceURL(
            named: name,
            withExtension: fileExtension,
            subdirectory: subdirectory,
            in: bundle
        )
        try Task.checkCancellation()
        let data = try Data(contentsOf: url, options: options)
        try Task.checkCancellation()
        let value = try decoder.decode(type, from: data)
        try Task.checkCancellation()
        return value
    }
}
