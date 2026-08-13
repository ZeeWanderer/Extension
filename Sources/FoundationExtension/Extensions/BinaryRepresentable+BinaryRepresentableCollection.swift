//
//  BinaryRepresentable+BinaryRepresentableCollection.swift
//
//
//  Created by zeewanderer on 11.08.2026.
//

import Foundation

internal enum P_BinaryCollectionFormat
{
    static func encode<CollectionType>(_ collection: CollectionType) -> Data
    where CollectionType: BinaryRepresentableCollection
    {
        if let data = collection.withContiguousStorageIfAvailable({ buffer in
            Data(buffer: buffer)
        }) {
            return data
        }

        let contiguous = ContiguousArray(collection)
        return contiguous.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }

    static func decode<CollectionType>(
        _ type: CollectionType.Type,
        from data: Data
    ) -> CollectionType?
    where CollectionType: BinaryRepresentableCollection
    {
        let elementStride = MemoryLayout<CollectionType.Element>.stride
        guard elementStride > 0, data.count.isMultiple(of: elementStride) else {
            return nil
        }
        guard !data.isEmpty else {
            return CollectionType(UnsafeBufferPointer(start: nil, count: 0))
        }

        return data.withUnsafeBytes { rawBuffer -> CollectionType? in
            guard let baseAddress = rawBuffer.baseAddress else { return nil }

            if Int(bitPattern: baseAddress).isMultiple(
                of: MemoryLayout<CollectionType.Element>.alignment
            ) {
                return CollectionType(rawBuffer.bindMemory(to: CollectionType.Element.self))
            }

            return withUnsafeTemporaryAllocation(
                byteCount: data.count,
                alignment: MemoryLayout<CollectionType.Element>.alignment
            ) { temporaryBuffer in
                temporaryBuffer.copyMemory(from: rawBuffer)
                let alignedBuffer = UnsafeRawBufferPointer(temporaryBuffer)
                    .bindMemory(to: CollectionType.Element.self)
                return CollectionType(alignedBuffer)
            }
        }
    }
}

public extension BinaryRepresentable where Self: BinaryRepresentableCollection
{
    init(data: Data)
    {
        guard let value = P_BinaryCollectionFormat.decode(Self.self, from: data) else {
            preconditionFailure("Invalid binary collection representation for \(Self.self)")
        }
        self = value
    }

    init?(validating data: Data)
    {
        guard let value = P_BinaryCollectionFormat.decode(Self.self, from: data) else {
            return nil
        }
        self = value
    }

    var data: Data
    {
        P_BinaryCollectionFormat.encode(self)
    }
}
