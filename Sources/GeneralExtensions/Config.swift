//
//  Config.swift
//  
//
//  Created by Maksym Kulyk on 29.03.2022.
//

import Foundation

public struct Config
{
    public enum AppConfiguration
    {
        /// Determined by using DEBUG preprocessor flag
        case Debug
        /// Detected by cheking `Bundle.main.appStoreReceiptURL` for "sandboxReceipt" at runtime.
        case TestFlight
        /// Returned when not ``Debug`` and not ``TestFlight``.
        case AppStore
    }
    
    @usableFromInline
    internal static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    @inlinable
    public static var isDebug: Bool
    {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    @inlinable
    public static var appConfiguration: AppConfiguration
    {
        if isDebug
        {
            return .Debug
        }
        else if isTestFlight
        {
            return .TestFlight
        }
        else
        {
            return .AppStore
        }
    }
}
