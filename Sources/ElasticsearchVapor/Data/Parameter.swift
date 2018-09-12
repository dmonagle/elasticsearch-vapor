//
//  Parameter.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import Foundation

public protocol ESValue {
    func esString() throws -> String
}

public typealias ESDictionary = Dictionary<String, ESValue>
public typealias ESArray = Array<ESValue?>

public enum ESParameterError : ElasticsearchError {
    case requiredParameterIsEmpty(String)
    case typeMismatch
    case unableToEscapeString(String)
}

extension String {
    func elasticsearchEscape() throws -> String {
        guard let escaped = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ESParameterError.unableToEscapeString(self)
        }
        return escaped
    }
    
    func elasticsearchPathify() throws -> String {
        return try self.trimmingCharacters(in: ESCharacters.PathStripCharacters).elasticsearchEscape()
    }
}

// MARK - Basic Type Conformance

public protocol BasicESParameter : ESValue, CustomStringConvertible {
}

extension BasicESParameter {
    public func esString() -> String {
        return description
    }
}

extension String : BasicESParameter {}
extension Int : BasicESParameter {}
extension Double : BasicESParameter {}

// MARK: - Dictionary Conformance

extension Dictionary where Key == String, Value == ESValue {
    public func enforce(_ path: String) throws -> ESValue {
        guard let result = self[path] else { throw ESParameterError.requiredParameterIsEmpty(path) }
        return result
    }
    
    public func get<ParameterType : ESValue>(_ path: String, default defaultValue: ParameterType) throws -> ParameterType {
        guard let value = self[path] else { return defaultValue }
        guard let returnValue = value as? ParameterType else { throw ESParameterError.typeMismatch }
        return returnValue
    }
    
    /// Sets a key to the given value if it's not already set
    public mutating func setDefault(for key: Key, to value: ESValue) {
        if (self[key] == nil) { self[key] = value }
    }

    func queryString() -> String {
        var components: [String] = []
        
        for (key, value) in self {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                let encodedValue = try? value.esString().elasticsearchEscape() {
                components.append("\(encodedKey)=\(encodedValue)")
            }
        }
        
        return components.joined(separator: "&")
    }
}

// MARK: - Array Conformance

extension Array : ESValue where Element == ESValue? {
    public func esString() throws -> String {
        let list : [String] = try self.compactMap {$0}.map { try $0.esString().elasticsearchEscape() }.compactMap { $0 }
        return
            list
                .filter { !$0.isEmpty }
                .joined(separator: ",")
    }

    public func esPathify() throws -> String {
        let list : [String] = try self.map {
            guard let element = $0 else { return nil }
            if let array = element as? Array<ESValue?> {
                return try array.esString()
            }
            else {
                return try element.esString().elasticsearchPathify()
            }
        }.compactMap { $0 }
        return
            try list
                .filter { !$0.isEmpty }
                .joined(separator: "/").elasticsearchEscape()
    }
}

// MARK: -

internal struct ESCharacters {
    /// Defines the characters to strip out of a path representation
    static let PathStripCharacters : CharacterSet = {
        var chars = CharacterSet.whitespacesAndNewlines
        chars.insert("/")
        return chars
    }()
}


