//
//  JSONDecoder.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension JSONDecoder
{
    @inlinable
    func setLossyReporter(_ reporter: LossyDecodingReporter)
    {
        self.userInfo[.lossyReporter] = reporter
        self.userInfo[.decoderInstanceID] = UUID()
        self.userInfo[.decoderSentinel] = P_DecoderSentinel()
    }
}
