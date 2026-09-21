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
/// perform the same work directly in the caller's structured task, outside the
/// caller's actor, so an actor such as the main actor remains available.
///
/// Use ``detachedEncodingTask(for:priority:)`` or
/// ``detachedDecodingTask(of:from:priority:)->Task<Value,Error>`` to start work from synchronous code,
/// continue doing other work, and await the explicitly detached task later.
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

    // MARK: - Explicit detached task coding

    /// Starts encoding outside the caller's actor and returns its task handle.
    ///
    /// This is an explicit unstructured-concurrency bridge for synchronous
    /// callers. Prefer ``encodeAsync(_:)`` from an asynchronous context.
    /// The caller owns the returned task's lifetime and cancellation.
    ///
    /// The value must be `Sendable` because it crosses into the detached task.
    /// Cancellation is checked before and after Foundation's synchronous
    /// `encode` call; that call cannot be interrupted once it has started.
    public func detachedEncodingTask<Value>(
        for value: Value,
        priority: TaskPriority? = nil
    ) -> Task<Data, Error>
    where Value: Encodable, Value: Sendable
    {
        return Task.detached(priority: priority) { try await encodeAsync(value) }
    }

    /// Starts decoding in an explicitly detached task and returns its handle.
    public func detachedDecodingTask<Value>(
        of type: Value.Type,
        from data: Data,
        priority: TaskPriority? = nil
    ) -> Task<Value, Error>
    where Value: Decodable, Value: Sendable
    {
        return Task.detached(priority: priority) { try await decodeAsync(type, from: data) }
    }

    /// Starts encoding and writing in an explicitly detached task.
    public func detachedEncodingTask<Value>(
        for value: Value,
        to url: URL,
        options: Data.WritingOptions = [.atomic],
        priority: TaskPriority? = nil
    ) -> Task<Void, Error>
    where Value: Encodable, Value: Sendable
    {
        return Task.detached(priority: priority) { try await encodeAsync(value, to: url, options: options) }
    }

    /// Starts reading and decoding in an explicitly detached task.
    public func detachedDecodingTask<Value>(
        of type: Value.Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = [],
        priority: TaskPriority? = nil
    ) -> Task<Value, Error>
    where Value: Decodable, Value: Sendable
    {
        return Task.detached(priority: priority) { try await decodeAsync(type, contentsOf: url, options: options) }
    }

    /// Starts loading and decoding a resource in an explicitly detached task.
    public func detachedDecodingTask<Value>(
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

    // MARK: - Awaited asynchronous coding

    /// Encodes directly in the caller's structured task, outside its actor.
    @concurrent
    public func encodeAsync<Value>(
        _ value: Value
    ) async throws -> Data
    where Value: Encodable, Value: Sendable
    {
        try Task.checkCancellation()
        let data = try encoder.encode(value)
        try Task.checkCancellation()
        return data
    }

    /// Decodes directly in the caller's structured task, outside its actor.
    @concurrent
    public func decodeAsync<Value>(
        _ type: Value.Type,
        from data: Data
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
    {
        try Task.checkCancellation()
        let value = try decoder.decode(type, from: data)
        try Task.checkCancellation()
        return value
    }

    /// Encodes and writes directly in the caller's structured task, outside its actor.
    @concurrent
    public func encodeAsync<Value>(
        _ value: Value,
        to url: URL,
        options: Data.WritingOptions = [.atomic]
    ) async throws
    where Value: Encodable, Value: Sendable
    {
        try Task.checkCancellation()
        let data = try encoder.encode(value)
        try Task.checkCancellation()
        try data.write(to: url, options: options)
    }

    /// Reads and decodes directly in the caller's structured task, outside its actor.
    @concurrent
    public func decodeAsync<Value>(
        _ type: Value.Type,
        contentsOf url: URL,
        options: Data.ReadingOptions = []
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
    {
        try Task.checkCancellation()
        let data = try Data(contentsOf: url, options: options)
        try Task.checkCancellation()
        let value = try decoder.decode(type, from: data)
        try Task.checkCancellation()
        return value
    }

    /// Loads and decodes a resource directly in the caller's task, outside its actor.
    @concurrent
    public func decodeAsync<Value>(
        _ type: Value.Type,
        fromResource name: String,
        withExtension fileExtension: String? = "json",
        subdirectory: String? = nil,
        in bundle: Bundle = .main,
        options: Data.ReadingOptions = []
    ) async throws -> Value
    where Value: Decodable, Value: Sendable
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
}
