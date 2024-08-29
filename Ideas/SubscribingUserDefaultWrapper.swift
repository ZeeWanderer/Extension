//
//  SubscribingUserDefaultWrapper.swift
//
//
//  Created by zee wanderer on 07.08.2024.
//

import Foundation
import Combine
import SwiftUI

/// A subscribing wrapper for a value stored in UserDefaults
@propertyWrapper
public class SubscribingUserDefault<Value>: DynamicProperty {
    @usableFromInline
    internal var cancellable: AnyCancellable?
    @usableFromInline
    internal var subject: CurrentValueSubject<Value, Never>
    
    @usableFromInline
    internal let get: () -> Value
    @usableFromInline
    internal let set: (Value) -> Void
    
    @inlinable
    public var wrappedValue: Value {
        get { get() }
        set {
            set(newValue)
            subject.send(newValue)
        }
    }
    
    @inlinable
    public var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    @usableFromInline
    internal init(get: @escaping () -> Value, set: @escaping (Value) -> Void, subject: CurrentValueSubject<Value, Never>, key: String, store: UserDefaults) {
        self.get = get
        self.set = set
        self.subject = subject
        
        // Subscribe to UserDefaults changes
        self.cancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: store)
            .sink { [weak self] _ in
                if let value = store.object(forKey: key) as? Value {
                    self?.subject.send(value)
                }
            }
    }
}

public extension SubscribingUserDefault {
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == Bool {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == Int {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == Double {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == String {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == URL {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value == Data {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? wrappedValue
        }, set: { newValue in
            store.set(newValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
}

public extension SubscribingUserDefault where Value: ExpressibleByNilLiteral {
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == Bool? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == Int? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == Double? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == String? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == URL? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(_ key: String, store: UserDefaults = .standard) where Value == Data? {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            let value = store.object(forKey: key) as? Value
            return value ?? nil
        }, set: { newValue in
            if let newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
}

public extension SubscribingUserDefault where Value: RawRepresentable {
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value.RawValue == String {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            if let rawValue = store.object(forKey: key) as? Value.RawValue {
                return Value(rawValue: rawValue) ?? wrappedValue
            }
            return wrappedValue
        }, set: { newValue in
            store.set(newValue.rawValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) where Value.RawValue == Int {
        let subject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.init(get: {
            if let rawValue = store.object(forKey: key) as? Value.RawValue {
                return Value(rawValue: rawValue) ?? wrappedValue
            }
            return wrappedValue
        }, set: { newValue in
            store.set(newValue.rawValue, forKey: key)
        }, subject: subject, key: key, store: store)
    }
}

public extension SubscribingUserDefault {
    @inlinable
    convenience init<R>(_ key: String, store: UserDefaults = .standard) where Value == R?, R: RawRepresentable, R.RawValue == Int {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            if let rawValue = store.object(forKey: key) as? R.RawValue {
                return R(rawValue: rawValue)
            } else {
                return nil
            }
        }, set: { newValue in
            if let newValue {
                store.set(newValue.rawValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
    
    @inlinable
    convenience init<R>(_ key: String, store: UserDefaults = .standard) where Value == R?, R: RawRepresentable, R.RawValue == String {
        let subject = CurrentValueSubject<Value, Never>(nil)
        self.init(get: {
            if let rawValue = store.object(forKey: key) as? R.RawValue {
                return R(rawValue: rawValue)
            } else {
                return nil
            }
        }, set: { newValue in
            if let newValue {
                store.set(newValue.rawValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }, subject: subject, key: key, store: store)
    }
}
