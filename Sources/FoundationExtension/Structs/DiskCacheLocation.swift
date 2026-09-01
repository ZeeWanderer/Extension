//
//  DiskCacheLocation.swift
//  Extension
//
//  Created by zeewanderer on 13.08.2026.
//

import Foundation

/// A system-aware parent location for persistent cache storage.
@available(iOS 18.4, macCatalyst 18.4, macOS 15.4, *)
public struct DiskCacheLocation: Hashable, Sendable
{
    /// A standardized directory inside an App Group container.
    public enum AppGroupDirectory: Hashable, Sendable
    {
        /// `Library/Caches`, which is purgeable and excluded from backup.
        case caches
        /// `Library/Application Support`, which persists until explicitly removed.
        case applicationSupport
        /// The group container itself.
        case container
    }

    @usableFromInline
    internal enum P_Base: Hashable, Sendable
    {
        case caches
        case applicationSupport
        case temporary
        case appGroup(String, AppGroupDirectory)
        case custom(URL)
    }

    @usableFromInline internal let p_base: P_Base
    @usableFromInline internal let p_excludesFromBackup: Bool?

    @inlinable
    internal init(
        base: P_Base,
        excludesFromBackup: Bool?
    )
    {
        self.p_base = base
        self.p_excludesFromBackup = excludesFromBackup
    }

    /// The app-specific system caches directory.
    public static let cachesDirectory = Self(
        base: .caches,
        excludesFromBackup: nil
    )

    /// The app-specific Application Support directory.
    ///
    /// Cache content is excluded from backup by default even though Application
    /// Support itself is normally backed up.
    @inlinable
    public static func applicationSupportDirectory(
        excludesFromBackup: Bool = true
    ) -> Self
    {
        Self(
            base: .applicationSupport,
            excludesFromBackup: excludesFromBackup
        )
    }

    /// The process temporary directory.
    public static let temporaryDirectory = Self(
        base: .temporary,
        excludesFromBackup: nil
    )

    /// A standardized location in an entitled App Group container.
    @inlinable
    public static func appGroup(
        _ identifier: String,
        directory: AppGroupDirectory = .caches,
        excludesFromBackup: Bool? = nil
    ) -> Self
    {
        Self(
            base: .appGroup(identifier, directory),
            excludesFromBackup: excludesFromBackup
                ?? (directory == .caches ? nil : true)
        )
    }

    /// A caller-supplied writable parent directory.
    ///
    /// Sandbox permissions and security-scoped access remain the caller's
    /// responsibility. Pass a backup setting when the chosen directory is
    /// normally backed up but contains replaceable data.
    @inlinable
    public static func custom(
        _ directory: URL,
        excludesFromBackup: Bool? = nil
    ) -> Self
    {
        Self(
            base: .custom(directory),
            excludesFromBackup: excludesFromBackup
        )
    }

    @usableFromInline
    internal func p_resolvedDirectory(
        fileManager: FileManager
    ) throws -> URL
    {
        switch p_base
        {
        case .caches:
            return Self.p_appSpecificDirectory(below: URL.cachesDirectory)
        case .applicationSupport:
            return Self.p_appSpecificDirectory(
                below: URL.applicationSupportDirectory
            )
        case .temporary:
            return fileManager.temporaryDirectory
        case let .appGroup(identifier, directory):
            guard !identifier.isEmpty,
                  let container = fileManager.containerURL(
                    forSecurityApplicationGroupIdentifier: identifier
                  ) else
            {
                throw CacheError.invalidDiskConfiguration(
                    "The App Group container is unavailable"
                )
            }
            switch directory
            {
            case .caches:
                return container
                    .appending(component: "Library", directoryHint: .isDirectory)
                    .appending(component: "Caches", directoryHint: .isDirectory)
            case .applicationSupport:
                return container
                    .appending(component: "Library", directoryHint: .isDirectory)
                    .appending(
                        component: "Application Support",
                        directoryHint: .isDirectory
                    )
            case .container:
                return container
            }
        case let .custom(directory):
            guard directory.isFileURL else
            {
                throw CacheError.invalidDiskConfiguration(
                    "A custom cache location must be a file URL"
                )
            }
            return directory
        }
    }

    @usableFromInline
    internal static func p_appSpecificDirectory(below directory: URL) -> URL
    {
        let identifier = Bundle.main.bundleIdentifier ?? "Extension"
        return directory.appending(
            component: identifier,
            directoryHint: .isDirectory
        )
    }
}
