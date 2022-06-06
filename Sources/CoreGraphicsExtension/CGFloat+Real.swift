//
//  File.swift
//  
//
//  Created by Maksym Kulyk on 06.06.2022.
//

import CoreGraphics
import RealModule

extension CGFloat: Real
{
    @_transparent
    public static func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
        return CoreGraphics.atan2(y, x)
    }
    
    @_transparent
    public static func erf(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.erf(x)
    }
    
    @_transparent
    public static func erfc(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.erfc(x)
    }
    
    @_transparent
    public static func exp2(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.exp2(x)
    }
    
    @_transparent
    public static func hypot(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        return CoreGraphics.hypot(x, y)
    }
    
    @_transparent
    public static func gamma(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.tgamma(x)
    }
    
    @_transparent
    public static func log2(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.log2(x)
    }
    
    @_transparent
    public static func log10(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.log10(x)
    }
    
    @_transparent
    public static func logGamma(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.lgamma(x)
    }
    
    @_transparent
    public static func exp(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.exp(x)
    }
    
    @_transparent
    public static func expMinusOne(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.expm1(x)
    }
    
    @_transparent
    public static func cosh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.cosh(x)
    }
    
    @_transparent
    public static func sinh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.sinh(x)
    }
    
    @_transparent
    public static func tanh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.tanh(x)
    }
    
    @_transparent
    public static func cos(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.cos(x)
    }
    
    @_transparent
    public static func sin(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.sin(x)
    }
    
    @_transparent
    public static func tan(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.tan(x)
    }
    
    @_transparent
    public static func log(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.log(x)
    }
    
    @_transparent
    public static func log(onePlus x: CGFloat) -> CGFloat {
        return CoreGraphics.log1p(x)
    }
    
    @_transparent
    public static func acosh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.acosh(x)
    }
    
    @_transparent
    public static func asinh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.asinh(x)
    }
    
    @_transparent
    public static func atanh(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.atanh(x)
    }
    
    @_transparent
    public static func acos(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.acos(x)
    }
    
    @_transparent
    public static func asin(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.asin(x)
    }
    
    @_transparent
    public static func atan(_ x: CGFloat) -> CGFloat {
        return CoreGraphics.atan(x)
    }
    
    @_transparent
    public static func pow(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        return CoreGraphics.pow(x, y)
    }
    
    @_transparent
    public static func pow(_ x: CGFloat, _ n: Int) -> CGFloat {
        if let y = CGFloat(exactly: n) { return CoreGraphics.pow(x, y) }
        
        let mask = Int(truncatingIfNeeded: UInt32.max)
        let round = n < 0 ? mask : 0
        let high = (n &+ round) & ~mask
        let low = n &- high
        return CoreGraphics.pow(x, CGFloat(low)) * CoreGraphics.pow(x, CGFloat(high))
    }
    
    @_transparent
    public static func root(_ x: CGFloat, _ n: Int) -> CGFloat {
        guard x >= 0 || n % 2 != 0 else { return .nan }
        // Workaround the issue mentioned below for the specific case of n = 3
        // where we can fallback on cbrt.
        if n == 3 { return CoreGraphics.cbrt(x) }
        // TODO: this implementation is not quite correct, because either n or
        // 1/n may be not be representable as Double.
        return CGFloat(signOf: x, magnitudeOf: CoreGraphics.pow(x.magnitude, 1/CGFloat(n)))
    }
}
