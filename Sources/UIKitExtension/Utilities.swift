//
//  Utilities.swift
//
//
//  Created by Maksym Kulyk on 09.08.2023.
//

#if canImport(UIKit) // TODO: port this
import UIKit
import CoreGraphicsExtension

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
    case .phone: if let phone {return phone()} else {break}
    case .pad: if let pad {return pad()} else {break}
    case .mac: if let mac {return mac()} else {break}
    case .tv: if let tv {return tv()} else {break}
    case .carPlay: if let carPlay {return carPlay()} else {break}
    case .vision: if let vision {return vision()} else {break}
    case .unspecified: break
    @unknown default: break
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
    case .phone: if let phone {return phone} else {break}
    case .pad: if let pad {return pad} else {break}
    case .mac: if let mac {return mac} else {break}
    case .tv: if let tv {return tv} else {break}
    case .carPlay: if let carPlay {return carPlay} else {break}
    case .vision: if let vision {return vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    return universal
}

@MainActor @inlinable
public func scaleValue<N>(universal: N,
                          phone: N? = nil,
                          pad:N? = nil,
                          mac:N? = nil,
                          tv:N? = nil,
                          carPlay:N? = nil,
                          vision:N? = nil) -> N where N : Numeric
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone: if let phone {return universal * phone} else {break}
    case .pad: if let pad {return universal * pad} else {break}
    case .mac: if let mac {return universal * mac} else {break}
    case .tv: if let tv {return universal * tv} else {break}
    case .carPlay: if let carPlay {return universal * carPlay} else {break}
    case .vision: if let vision {return universal * vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    return universal
}

@MainActor @inlinable
public func scaleValue<V, S>(universal: V,
                             phone: S? = nil,
                             pad:S? = nil,
                             mac:S? = nil,
                             tv:S? = nil,
                             carPlay:S? = nil,
                             vision:S? = nil) -> V where V : Numeric2D, S == V.Magnitude
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone: if let phone {return universal * phone} else {break}
    case .pad: if let pad {return universal * pad} else {break}
    case .mac: if let mac {return universal * mac} else {break}
    case .tv: if let tv {return universal * tv} else {break}
    case .carPlay: if let carPlay {return universal * carPlay} else {break}
    case .vision: if let vision {return universal * vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    
    return universal
}

@MainActor @inlinable
public func scaleValue<V, S>(universal: V,
                             phone: S? = nil,
                             pad:S? = nil,
                             mac:S? = nil,
                             tv:S? = nil,
                             carPlay:S? = nil,
                             vision:S? = nil) -> V where V : Numeric2D, S : Numeric2D, V.Magnitude == S.Magnitude
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone: if let phone {return universal .* phone} else {break}
    case .pad: if let pad {return universal .* pad} else {break}
    case .mac: if let mac {return universal .* mac} else {break}
    case .tv: if let tv {return universal .* tv} else {break}
    case .carPlay: if let carPlay {return universal .* carPlay} else {break}
    case .vision: if let vision {return universal .* vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    
    return universal
}

@MainActor @inlinable
public func scaleValue(universal: CGRect,
                       phone: CGFloat? = nil,
                       pad:CGFloat? = nil,
                       mac:CGFloat? = nil,
                       tv:CGFloat? = nil,
                       carPlay:CGFloat? = nil,
                       vision:CGFloat? = nil) -> CGRect
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone: if let phone {return universal * phone} else {break}
    case .pad: if let pad {return universal * pad} else {break}
    case .mac: if let mac {return universal * mac} else {break}
    case .tv: if let tv {return universal * tv} else {break}
    case .carPlay: if let carPlay {return universal * carPlay} else {break}
    case .vision: if let vision {return universal * vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    
    return universal
}

@MainActor @inlinable
public func scaleValue<N>(universal: CGRect,
                          phone: N? = nil,
                          pad:N? = nil,
                          mac:N? = nil,
                          tv:N? = nil,
                          carPlay:N? = nil,
                          vision:N? = nil) -> CGRect where N: Numeric2D, N.Magnitude == CGFloat
{
    switch UIDevice.current.userInterfaceIdiom
    {
    case .phone: if let phone {return universal .* phone} else {break}
    case .pad: if let pad {return universal .* pad} else {break}
    case .mac: if let mac {return universal .* mac} else {break}
    case .tv: if let tv {return universal .* tv} else {break}
    case .carPlay: if let carPlay {return universal .* carPlay} else {break}
    case .vision: if let vision {return universal .* vision} else {break}
    case .unspecified: break
    @unknown default: break
    }
    
    return universal
}
#endif
