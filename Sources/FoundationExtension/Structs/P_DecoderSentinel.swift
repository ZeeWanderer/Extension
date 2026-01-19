//
//  P_DecoderSentinel.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

@usableFromInline
internal final class P_DecoderSentinel: CustomStringConvertible, Sendable
{
    let id = UUID()
    
    @usableFromInline
    init() {}
    
    @usableFromInline
    var description: String { "Sentinel(\(id))" }
}
