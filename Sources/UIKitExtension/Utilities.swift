//
//  Utilities.swift
//  
//
//  Created by Maksym Kulyk on 09.08.2023.
//

import UIKit

@MainActor @inlinable
public func selectValue<V>(universal: () -> V,
                           phone: (() -> V)? = nil,
                           pad: (() -> V)? = nil,
                           mac: (() -> V)? = nil,
                           tv: (() -> V)? = nil,
                           carPlay: (() -> V)? = nil,
                           vision: (() -> V)? = nil) -> V
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone:
        if let phone
        {return phone()}
        else
        {break}
    case .pad:
        if let pad
        {return pad()}
        else
        {break}
    case .mac:
        if let mac
        {return mac()}
        else
        {break}
    case .tv:
        if let tv
        {return tv()}
        else
        {break}
    case .carPlay:
        if let carPlay
        {return carPlay()}
        else
        {break}
    case .vision:
        if let vision
        {return vision()}
        else
        {break}
    case .unspecified:
        break
    @unknown default:
        break
    }
    
    return universal()
}

@MainActor @inlinable
public func selectValue<V>(universal: V, 
                           phone: V? = nil,
                           pad:V? = nil,
                           mac:V? = nil,
                           tv:V? = nil,
                           carPlay:V? = nil,
                           vision:V? = nil) -> V
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone:
        if let phone
        {return phone}
        else
        {break}
    case .pad:
        if let pad
        {return pad}
        else
        {break}
    case .mac:
        if let mac
        {return mac}
        else
        {break}
    case .tv:
        if let tv
        {return tv}
        else
        {break}
    case .carPlay:
        if let carPlay
        {return carPlay}
        else
        {break}
    case .vision:
        if let vision
        {return vision}
        else
        {break}
    case .unspecified:
        break
    @unknown default:
        break
    }
    
    return universal
}
