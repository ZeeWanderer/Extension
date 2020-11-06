//
//  Bundle.swift
//  Extension
//
//  Created by Maksym Kulyk on 7/7/20.
//  Copyright © 2020 max. All rights reserved.
//

import UIKit

extension Bundle
{
    public var releaseVersionNumber: String?
    {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    public var buildVersionNumber: String?
    {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
