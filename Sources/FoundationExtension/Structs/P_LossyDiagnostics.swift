//
//  P_LossyDiagnostics.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

@usableFromInline
internal struct P_LossyDiagnostics
{
    private init() {}
    
    @usableFromInline
    static func reportMissingReporter(decoder: Decoder, note: StaticString) {
        let id = (decoder.userInfo[.decoderInstanceID] as? UUID)?.uuidString ?? "nil"
        let sentinel = decoder.userInfo[.decoderSentinel] as Any
        let path = decoder.codingPath.map { $0.stringValue }.joined(separator: ".")
        let keys = decoder.userInfo.keys.map(\.rawValue)
        let stack = Thread.callStackSymbols.joined(separator: "\n")
        print("""
        WARNING: Missing lossyReporter [\(note)]
        codingPath=\(path.isEmpty ? "<root>" : path)
        decoderInstanceID=\(id)
        sentinel=\(sentinel)
        userInfoKeys=\(keys)
        stack:
        \(stack)
        """)
    }
}
