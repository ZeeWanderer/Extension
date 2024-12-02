//
//  SwiftUI.swift
//  
//
//  Created by Maksym Kulyk on 09.03.2022.
//

import SwiftUI

#if canImport(UIKitExtension)
// MARK: - UIEdgeInsets
public extension UIEdgeInsets
{
    @inlinable
    var swiftUIInsets: EdgeInsets
    {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
#endif

// MARK: - EdgeInsets
public extension EdgeInsets
{
    @inlinable
    static var zero: EdgeInsets
    {
        .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var trailingDefaultPadding: CGFloat?
    {
        trailing == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var leadingDefaultPadding: CGFloat?
    {
        leading == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var topDefaultPadding: CGFloat?
    {
        top == 0 ? nil : 0
    }
    
    /// Returns default padding if inset is 0
    @inlinable
    var bottomDefaultPadding: CGFloat?
    {
        bottom == 0 ? nil : 0
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat, y scaleY: CGFloat) -> EdgeInsets
    {
        .init(top: top * scaleY, leading: leading * scaleX, bottom: bottom * scaleY, trailing: trailing * scaleX)
    }
    
    @inlinable
    @inline(__always)
    func scaled(x scaleX: CGFloat) -> EdgeInsets
    {
        .init(top: top, leading: leading * scaleX, bottom: bottom, trailing: trailing * scaleX)
    }
    
    @inlinable
    @inline(__always)
    func scaled(y scaleY: CGFloat) -> EdgeInsets
    {
        .init(top: top * scaleY, leading: leading, bottom: bottom * scaleY, trailing: trailing)
    }
    
    @inlinable
    @inline(__always)
    func scaled(_ scale: CGFloat) -> EdgeInsets
    {
        return self * scale
    }
    
    @inlinable
    @inline(__always)
    static func .* <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == CGFloat
    {
        return .init(top: lhs.top * rhs.yMagnitude, leading: lhs.leading * rhs.xMagnitude, bottom: lhs.bottom * rhs.yMagnitude, trailing: lhs.trailing * rhs.xMagnitude)
    }
    
    @inlinable
    func inset(for edge: Edge) -> CGFloat
    {
        switch edge {
        case .top:
            return self.top
        case .leading:
            return self.leading
        case .bottom:
            return self.bottom
        case .trailing:
            return self.trailing
        }
    }
    
    @inlinable
    func inset(for edge: Edge, or default: CGFloat) -> CGFloat
    {
        let inset_ = self.inset(for: edge)
        return inset_ == 0 ? `default` : inset_
    }
}

// MARK: - Color

// MARK: - UnitPoint
public extension UnitPoint
{
    @inlinable
    @inline(__always)
    var cgPoint: CGPoint
    {
        return .init(x: self.x, y: self.y)
    }
}

// MARK: - Animation
public extension Animation
{
    @inlinable
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation
    {
        if expression
        {
            return self.repeatForever(autoreverses: autoreverses)
        }
        else
        {
            return self
        }
    }
}

// MARK: - Angle
public extension Angle
{
    @inlinable
    @inline(__always) var quarter: Int
    {
        Int((abs(self.degrees).truncatingRemainder(dividingBy: 360)) / 90.0)
    }
}

// MARK: - GeometryProxy
public extension GeometryProxy
{
    @inlinable
    @inline(__always) func scale(for refernce: CGSize) -> CGPoint
    {
        return CGPoint(self.size ./ refernce)
    }
}

// MARK: - TimelineSchedule
public extension TimelineSchedule
{
    @inlinable
    static func cyclic(timeOffsets: [TimeInterval]) -> CyclicTimelineSchedule where Self == CyclicTimelineSchedule {
        .init(timeOffsets: timeOffsets)
    }
    
    @inlinable
    static func explicit<S>(timeOffsets: [TimeInterval], referenceDate: Date = .now) -> ExplicitTimelineSchedule<[Date]> where Self == ExplicitTimelineSchedule<S>, S : Sequence, S.Element == Date
    {
        let now = referenceDate
        return .init(timeOffsets.map({ offset in
            now.addingTimeInterval(offset)
        }))
    }
}

// MARK: - Structs -



// MARK: - Shadow
/// A struct that describes SwiftUi shadow
public struct Shadow
{
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    @inlinable
    public init(color: Color = .init(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0)
    {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    @inlinable
    public static func * (lhs: Self, rhs: CGFloat) -> Self
    {
        return Self(color: lhs.color, radius: lhs.radius * rhs, x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    @inlinable
    public static func * <T>(lhs: Self, rhs: T) -> Self where T: Numeric2D, T.Magnitude == CGFloat
    {
        let minScale = min(rhs.xMagnitude, rhs.yMagnitude)
        return Self(color: lhs.color, radius: lhs.radius * minScale, x: lhs.x * rhs.xMagnitude, y: lhs.y * rhs.yMagnitude)
    }
}

// MARK: - CyclicTimelineSchedule
public struct CyclicTimelineSchedule: TimelineSchedule
{
    public let timeOffsets: [TimeInterval]
    
    @inlinable
    public init(timeOffsets: [TimeInterval])
    {
        self.timeOffsets = timeOffsets
    }
    
    @inlinable
    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries
    {
        Entries(last: startDate, offsets: timeOffsets)
    }
    
    public struct Entries: Sequence, IteratorProtocol 
    {
        @usableFromInline var last: Date
        @usableFromInline let offsets: [TimeInterval]
        
        @inlinable
        public init(last: Date, offsets: [TimeInterval])
        {
            self.last = last
            self.offsets = offsets
        }
        
        @usableFromInline
        var idx: Int = -1
        
        @inlinable
        mutating public func next() -> Date?
        {
            idx = (idx + 1) % offsets.count
            
            last = last.addingTimeInterval(offsets[idx])
            
            return last
        }
    }
}
