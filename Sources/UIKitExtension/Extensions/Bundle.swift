//
//  Bundle.swift
//  Extension
//
//  Created by zeewanderer on 7/7/20.
//  Copyright © 2020 max. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension Bundle
{
    @inlinable
    var releaseVersionNumber: String?
    {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    @inlinable
    var buildVersionNumber: String?
    {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
#endif
