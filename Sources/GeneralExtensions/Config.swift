//
//  Config.swift
//  
//
//  Created by zeewanderer on 29.03.2022.
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
    
    public static let isTestFlight: Bool = {
#if targetEnvironment(macCatalyst)
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        var requirement: SecRequirement?
        let reqString = "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.25.1]" as CFString
        let reqStatus = SecRequirementCreateWithString(reqString, [], &requirement)
        guard reqStatus == errSecSuccess, let req = requirement else {
            return false
        }
        
        let checkStatus = SecStaticCodeCheckValidity(code, [], req)
        return checkStatus == errSecSuccess
        
#else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }()
    
    @_transparent
    public static var isDebug: Bool
    {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    @inlinable
    public static var isTestFlightOrDebug: Bool
    {
        return isDebug || isTestFlight
    }
    
    @inlinable
    public static var appConfiguration: AppConfiguration
    {
#if DEBUG
        return .Debug
#else
        if isTestFlight
        {
            return .TestFlight
        }
        else
        {
            return .AppStore
        }
#endif
    }
}
