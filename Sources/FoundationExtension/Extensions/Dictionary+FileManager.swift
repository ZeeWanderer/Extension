//
//  Dictionary+FileManager.swift
//
//
//  Created by zee wanderer on 07.08.2024.
//

import Foundation

public extension Dictionary where Key == FileAttributeKey, Value == Any
{
    /// Returns the file’s size, in bytess.
    /// - Returns: The value associated with the size file attributes key, as a UInt64, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileSize: UInt64? {
        return self[.size] as? UInt64
    }
    
    /// Returns file’s modification date.
    /// - Returns: The value associated with the modificationDate file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileModificationDate: Date? {
        return self[.modificationDate] as? Date
    }
    
    /// Returns the file type.
    /// - Returns: The value associated with the type file attributes key, or nil if the file attributes dictionary has no entry for the key. For possible values, see FileAttributeType.
    @inlinable
    @inline(__always)
    var fileType: String? {
        return self[.type] as? String
    }
    
    /// Returns the file’s POSIX permissions.
    /// - Returns: The value associated with the posixPermissions file attributes key as an Int, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var filePosixPermissions: Int? {
        return self[.posixPermissions] as? Int
    }
    
    /// Returns the file’s owner account name.
    /// - Returns: The value associated with the ownerAccountName file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileOwnerAccountName: String? {
        return self[.ownerAccountName] as? String
    }
    
    /// Returns the file’s group owner account name.
    /// - Returns: The value associated with the groupOwnerAccountName file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileGroupOwnerAccountName: String? {
        return self[.groupOwnerAccountName] as? String
    }
    
    /// Returns the filesystem number.
    /// - Returns: The value associated with the systemNumber file attributes key as an Int, or nil if the file attributes dictionary has no entry for the key
    @inlinable
    @inline(__always)
    var fileSystemNumber: Int? {
        return self[.systemNumber] as? Int
    }
    
    /// Returns the filesystem file number.
    /// - Returns: The value associated with the systemFileNumber file attributes key as an Int, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileSystemFileNumber: Int? {
        return self[.systemFileNumber] as? Int
    }
    
    /// Returns a Boolean value indicating whether the file hides its extension.
    /// - Returns: The value associated with the extensionHidden file attributes key, or false if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileExtensionHidden: Bool? {
        return self[.extensionHidden] as? Bool
    }
    
    /// Returns the file’s HFS creator code.
    /// - Returns: The value associated with the hfsCreatorCode file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileHFSCreatorCode: OSType? {
        return self[.hfsCreatorCode] as? OSType
    }
    
    /// Returns file’s HFS type code.
    /// - Returns: The value associated with the hfsTypeCode file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileHFSTypeCode: OSType? {
        return self[.hfsTypeCode] as? OSType
    }
    
    /// Returns a Boolean value indicating whether the file is immutable.
    /// - Returns: The value associated with the immutable file attributes key, or false if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileIsImmutable: Bool? {
        return self[.immutable] as? Bool
    }
    
    /// Returns a Boolean value indicating whether the file is append only.
    /// - Returns: The value associated with the appendOnly file attributes key, or false if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileIsAppendOnly: Bool? {
        return self[.appendOnly] as? Bool
    }
    
    /// Get the creation date from the file attributes dictionary.
    /// - Returns: The value associated with the creationDate file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileCreationDate: Date? {
        return self[.creationDate] as? Date
    }
    
    /// Returns the file’s owner account ID.
    /// - Returns: The value associated with the ownerAccountID file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileOwnerAccountID: NSNumber? {
        return self[.ownerAccountID] as? NSNumber
    }
    
    /// Returns file’s group owner account ID.
    /// - Returns: The value associated with the groupOwnerAccountID file attributes key, or nil if the file attributes dictionary has no entry for the key.
    @inlinable
    @inline(__always)
    var fileGroupOwnerAccountID: NSNumber? {
        return self[.groupOwnerAccountID] as? NSNumber
    }
}
