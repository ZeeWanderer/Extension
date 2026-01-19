//
//  Decoder.swift
//
//
//  Created by zeewanderer on 19.01.2026.
//

import Foundation

public extension Decoder
{
    @inlinable
    var lossyReporter: LossyDecodingReporter
    {
        let reporter = userInfo[.lossyReporter]
#if DEBUG
        guard let reporter else {
            P_LossyDiagnostics.reportMissingReporter(decoder: self, note: "Decoder.lossyReporter")
            return NoopLossyReporter()
        }
#endif
        return (reporter as? LossyDecodingReporter) ?? NoopLossyReporter()
    }
}
