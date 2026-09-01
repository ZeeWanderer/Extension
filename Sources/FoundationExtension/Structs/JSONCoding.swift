//
//  JSONCoding.swift
//
//
//  Created by zeewanderer on 12.08.2026.
//

import Foundation

/// A synchronous and asynchronous facade over Foundation JSON coding.
///
/// Synchronous methods perform all work on the calling thread and return only
/// after encoding, decoding, or file access completes. Asynchronous methods
/// run the same synchronous Foundation operation in a detached task so a
/// caller such as the main actor remains available for other work.
///
/// Use ``encodingTask(for:priority:)`` or
/// ``decodingTask(of:from:priority:)`` to start work from synchronous code,
/// continue doing other work, and await the task's value later.
public struct JSONCoding: Sendable
{
    /// The encoder used by all encoding operations.
    public let encoder: JSONEncoder

    /// The decoder used by all decoding operations.
    public let decoder: JSONDecoder

    /// Creates a JSON coder from optionally preconfigured Foundation coders.
    ///
    /// Finish configuring the encoder and decoder before starting concurrent
    /// operations. Foundation declares both types `Sendable` on the package's
    /// supported platforms.
    public init(
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    )
    {
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - Synchronous data coding

    /// Encodes a value synchronously on the calling thread.
    public func encode<Value>(_ value: Value) throws -> Data
    where Value: Encodable
    {
        try encoder.encode(value)
    }

    /// Decodes a value synchronously on the calling thread.
    public func decode<Value>(
        _ type: Value.Type,
        from data: Data
    ) throws -> Value
    where Value: Decodable
    {
        try decoder.decode(type, from: data)
    }

    // MARK: - Synchronous file coding

    /// Encodes a value and writes it synchronously to a file.
    public func encode<Value>(
        _ value: Value,
        to url: URL,
        options: Data.WritingOptions = [.atomic]
    ) throws
    where Value: Encodable
    {
        try encode(value).write(to: url, options: options)
    }

    /// Reads a file and decodes its JSON synchronously.
    public func decode<Value>(
        _ type: Value.Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = []
    ) throws -> Value
    where Value: Decodable
    {
        try decode(type, from: Data(contentsOf: url, options: options))
    }

    /// Loads and decodes a JSON resource synchronously.
    public func decode<Value>(
        _ type: Value.Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = []
    ) throws -> Value
    where Value: Decodable
    {
        let url = try p_resourceURL(
            named: name,
            withExtension: fileExtension,
            subdirectory: subdirectory,
            in: bundle
        )
        return try decode(type, contentsOf: url, options: options)
    }

    // MARK: - Deferred task coding

    /// Starts encoding outside the caller's actor and returns its task handle.
    ///
    /// The value must be `Sendable` because it crosses into the detached task.
    /// Cancellation is checked before and after Foundation's synchronous
    /// `encode` call; that call cannot be interrupted once it has started.
    public func encodingTask<Value>(
        for value: Value,
        priority: TaskPriority? = nil
    ) -> Task<Data, Error>
    where Value: Encodable, Value: Sendable
    {
        let encoder = encoder
        return Task.detached(priority: priority)
        {
            try Task.checkCancellation()
            let data = try encoder.encode(value)
            try Task.checkCancellation()
            return data
        }
    }

    /// Starts decoding outside the caller's actor and returns its task handle.
    public func decodingTask<Value>(
        of type: Value.Type,
        from data: Data,
        priority: TaskPriority? = nil
    ) -> Task<Value, Error>
    where Value: Decodable, Value: Sendable
    {
        let decoder = decoder
        return Task.detached(priority: priority)
        {
            try Task.checkCancellation()
            let value = try decoder.decode(type, from: data)
            try Task.checkCancellation()
            return value
        }
    }

    /// Starts encoding and writing outside the caller's actor.
    public func encodingTask<Value>(
        for value: Value,
        to url: URL,
        options: Data.WritingOptions = [.atomic],
        priority: TaskPriority? = nil
    ) -> Task<Void, Error>
    where Value: Encodable, Value: Sendable
    {
        let encoder = encoder
        return Task.detached(priority: priority)
        {
            try Task.checkCancellation()
            let data = try encoder.encode(value)
            try Task.checkCancellation()
            try data.write(to: url, options: options)
            try Task.checkCancellation()
        }
    }

    /// Starts reading and decoding outside the caller's actor.
    public func decodingTask<Value>(
        of type: Value.Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) -> Task<Value, Error>
    where Value: Decodable, Value: Sendable
    {
        let decoder = decoder
        return Task.detached(priority: priority)
        {
            try Task.checkCancellation()
            let data = try Data(contentsOf: url, options: options)
            try Task.checkCancellation()
            let value = try decoder.decode(type, from: data)
            try Task.checkCancellation()
            return value
        }
    }

    /// Starts loading and decoding a bundled JSON resource.
    public func decodingTask<Value>(
        of type: Value.Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) -> Task<Value, Error>
    where Value: Decodable, Value: Sendable
    {
        do
        {
            let url = try p_resourceURL(
                named: name,
                withExtension: fileExtension,
                subdirectory: subdirectory,
                in: bundle
            )
            return decodingTask(
                of: type,
                contentsOf: url,
                options: options,
                priority: priority
            )
        }
        catch
        {
            return Task.detached(priority: priority) { throw error }
        }
    }

    // MARK: - Awaited asynchronous coding

    /// Encodes outside the caller's actor and asynchronously returns the data.
    public func encodeAsync<Value>(
        _ value: Value,
        priority: TaskPriority? = nil
    ) async throws -> Data
    where Value: Encodable, Value: Sendable
    {
        try await p_result(
            of: encodingTask(for: value, priority: priority)
        )
    }

    /// Decodes outside the caller's actor and asynchronously returns the value.
    public func decodeAsync<Value>(
        _ type: Value.Type,
        from data: Data,
        priority: TaskPriority? = nil
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
    {
        try await p_result(
            of: decodingTask(of: type, from: data, priority: priority)
        )
    }

    /// Encodes and writes outside the caller's actor.
    public func encodeAsync<Value>(
        _ value: Value,
        to url: URL,
        options: Data.WritingOptions = [.atomic],
        priority: TaskPriority? = nil
    ) async throws
    where Value: Encodable, Value: Sendable
    {
        try await p_result(
            of: encodingTask(
                for: value,
                to: url,
                options: options,
                priority: priority
            )
        )
    }

    /// Reads and decodes outside the caller's actor.
    public func decodeAsync<Value>(
        _ type: Value.Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
    {
        try await p_result(
            of: decodingTask(
                of: type,
                contentsOf: url,
                options: options,
                priority: priority
            )
        )
    }

    /// Loads and decodes a bundled resource outside the caller's actor.
    public func decodeAsync<Value>(
        _ type: Value.Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
    {
        try await p_result(
            of: decodingTask(
                of: type,
                fromResource: name,
                withExtension: fileExtension,
                subdirectory: subdirectory,
                in: bundle,
                options: options,
                priority: priority
            )
        )
    }

    internal func p_resourceURL(
        named name: String,
        withExtension fileExtension: String?,
        subdirectory: String?,
        in bundle: Bundle
    ) throws -> URL
    {
        guard let url = bundle.url(
            forResource: name,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) else
        {
            throw JSONCodingError.resourceNotFound(
                name: name,
                fileExtension: fileExtension,
                subdirectory: subdirectory
            )
        }

        return url
    }

    internal func p_result<Success>(
        of task: Task<Success, Error>
    ) async throws -> Success
    where Success: Sendable
    {
        try await withTaskCancellationHandler
        {
            try await task.value
        }
        onCancel:
        {
            task.cancel()
        }
    }
}
