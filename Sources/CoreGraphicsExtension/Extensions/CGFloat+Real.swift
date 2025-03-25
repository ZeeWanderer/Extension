//
//  File.swift
//  
//
//  Created by zeewanderer on 06.06.2022.
//

import CoreGraphics
import RealModule

extension CGFloat: Real
{
    @_transparent
    public static func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.atan2(y: y, x: x)
    }
    
    @_transparent
    public static func erf(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.erf(x)
    }
    
    @_transparent
    public static func erfc(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.erfc(x)
    }
    
    @_transparent
    public static func exp2(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.exp2(x)
    }
    
    @_transparent
    public static func hypot(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        return CGFloat.NativeType.hypot(x, y)
    }
    
    @_transparent
    public static func gamma(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.gamma(x)
    }
    
    @_transparent
    public static func log2(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.log2(x)
    }
    
    @_transparent
    public static func log10(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.log10(x)
    }
    
    @_transparent
    public static func logGamma(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.logGamma(x)
    }
    
    @_transparent
    public static func exp(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.exp(x)
    }
    
    @_transparent
    public static func expMinusOne(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.expMinusOne(x)
    }
    
    @_transparent
    public static func cosh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.cosh(x)
    }
    
    @_transparent
    public static func sinh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.sinh(x)
    }
    
    @_transparent
    public static func tanh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.tanh(x)
    }
    
    @_transparent
    public static func cos(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.cos(x)
    }
    
    @_transparent
    public static func sin(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.sin(x)
    }
    
    @_transparent
    public static func tan(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.tan(x)
    }
    
    @_transparent
    public static func log(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.log(x)
    }
    
    @_transparent
    public static func log(onePlus x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.log(onePlus: x)
    }
    
    @_transparent
    public static func acosh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.acosh(x)
    }
    
    @_transparent
    public static func asinh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.asinh(x)
    }
    
    @_transparent
    public static func atanh(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.atanh(x)
    }
    
    @_transparent
    public static func acos(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.acos(x)
    }
    
    @_transparent
    public static func asin(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.asin(x)
    }
    
    @_transparent
    public static func atan(_ x: CGFloat) -> CGFloat {
        return CGFloat.NativeType.atan(x)
    }
    
    @_transparent
    public static func pow(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        return CGFloat.NativeType.pow(x, y)
    }
    
    @_transparent
    public static func pow(_ x: CGFloat, _ n: Int) -> CGFloat {
        return CGFloat.NativeType.pow(x, n)
    }
    
    @_transparent
    public static func root(_ x: CGFloat, _ n: Int) -> CGFloat {
        return CGFloat.NativeType.root(x, n)
    }
}
