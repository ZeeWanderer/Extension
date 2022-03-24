//
//  Collections.swift
//  
//
//  Created by Maksym Kulyk on 27.04.2021.
//

import Foundation

//MARK: - Collection
public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Index) -> Element?
    {
        return indices.contains(index) ? self[index] : nil
    }
}

//MARK: - Dictionary
public extension Dictionary where Key: Equatable, Value: Equatable
{
    @inlinable
    func minus(dict: [Key:Value]) -> [Key:Value]
    {
        let entriesInSelfAndNotInDict = filter { dict[$0.0] != self[$0.0] }
        return entriesInSelfAndNotInDict.reduce([Key:Value]()) { (res, entry) -> [Key:Value] in
            var res = res
            res[entry.0] = entry.1
            return res
        }
    }
}

extension Dictionary: RawRepresentable where Key: Codable, Value: Codable
{
    public init?(rawValue: String)
    {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Key:Value].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String
    {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return result
    }
}

// MARK: LocalizationDictionary
public typealias LanguageCodeKey = String
public typealias LocalizedStringValue = String
public typealias LocalizationDictionary = Dictionary<LanguageCodeKey, LocalizedStringValue>
public extension LocalizationDictionary
{
    @inlinable
    subscript(_ locale: Locale) -> LocalizedStringValue
    {
        // check provided locale
        if let languageCode = locale.languageCode, let l_string = self[languageCode]
        {
            return l_string
        }
        else // fallback on current locale if provided locale is not current
        if Locale.current != locale, let languageCode = Locale.current.languageCode, let l_string = self[languageCode]
        {
            return l_string
        }
        else // fallback on preffered languages
        {
            for language in Locale.preferredLanguages
            {
                let languageCode = String(language.prefix(2)) // exctract language code from language
                if let l_string = self[languageCode]
                {
                    return l_string
                }
            }
        }
        
        // return any value if there are any values at all
        return self.first?.value ?? ""
    }
}

//MARK: - Array
public extension Array
{
    @inlinable
    func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map
        {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    @inlinable
    subscript(safe range: Range<Index>) -> ArraySlice<Element>
    {
        let lowerBound = range.lowerBound
        if lowerBound < self.endIndex
        {
            return self[lowerBound..<Swift.min(range.endIndex, self.endIndex)]
        }
        else
        {
            return []
        }
    }
    
    @inlinable
    subscript(safe range: ClosedRange<Index>) -> ArraySlice<Element>
    {
        let lowerBound = range.lowerBound
        if lowerBound < self.endIndex
        {
            return self[lowerBound...Swift.min(range.upperBound, self.endIndex - 1)]
        }
        else
        {
            return []
        }
    }
}

extension Array: RawRepresentable where Element: Codable
{
    public init?(rawValue: String)
    {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String
    {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

//MARK: - Stackable
public protocol Stackable
{
    associatedtype Element
    func peek() -> Element?
    mutating func push(_ element: Element)
    @discardableResult mutating func pop() -> Element?
}

public extension Stackable
{
    @inlinable var isEmpty: Bool { peek() == nil }
}

public struct Stack<Element>: Stackable where Element: Equatable
{
    private var storage = [Element]()
    public func peek() -> Element? { storage.last }
    public mutating func push(_ element: Element) { storage.append(element)  }
    public mutating func pop() -> Element? { storage.popLast() }
}

extension Stack: Equatable
{
    public static func == (lhs: Stack<Element>, rhs: Stack<Element>) -> Bool { lhs.storage == rhs.storage }
}

extension Stack: CustomStringConvertible
{
    public var description: String { "\(storage)" }
}

extension Stack: ExpressibleByArrayLiteral
{
    public init(arrayLiteral elements: Self.Element...) { storage = elements }
}
