//
//  Indexing.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 29/8/18.
//

import Foundation
import HTTP


public enum ESIndexingError : ElasticsearchError {
    case errorCreatingUTF8String(Data)
}


/// A structure that represents an elasticsearch index name
public struct ESIndexName : CustomStringConvertible, Encodable {
    public var prefix : String?
    public var name : String

    public var description: String {
        get {
            if let prefix = prefix {
                return "\(prefix)\(name)"
            }
            else {
                return name
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init(prefix: String? = nil, _ name: String) {
        self.prefix = prefix
        self.name = name
    }
}

extension ESIndexName : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.name = value
    }
}

/// Makes any Codable model indexable by Elasticsearch
public protocol ESIndexable : Encodable {
    static var esIndex : ESIndexName { get }
    static var esType : String { get }

    var esId: String? { get }
    var esParentId: String? { get }
}

/// Default implementations
extension ESIndexable {
    public var esParentId: String? { get { return nil } }
}

/**
 Allows the indexing or deleting of ESIndexable documents
 */
public protocol ESIndexer {
    var eventLoop : EventLoop { get }
    func index(index: ESIndexName, type: String, id: String?, body: HTTPBody, query: ESDictionary) throws -> Future<Void>
    func delete(index: ESIndexName, type: String, id: String?, query: ESDictionary) -> Future<Void>
    func flush() throws -> Future<Void>
    var jsonEncoder : JSONEncoder { get }
}

public extension ESIndexer {
    func index<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary = [:]) throws -> Future<Void> where IndexableModel : ESIndexable {
        do {
            let body = try HTTPBody(data: self.encodeJson(indexable))
            return try self.index(index: IndexableModel.esIndex, type: IndexableModel.esType, id: indexable.esId, body: body, query: query)
        } catch {
            return self.eventLoop.future(error: error)
        }
    }
    func delete<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary = [:]) throws -> Future<Void> where IndexableModel : ESIndexable {
        return self.delete(index: IndexableModel.esIndex, type: IndexableModel.esType, id: indexable.esId, query: query)
    }

    func encodeJson<Model>(_ model: Model) throws -> Data where Model : Encodable {
        return try jsonEncoder.encode(model)
    }

    func encodeJsonBody(dictionary: Dictionary<String, Any>) throws -> HTTPBody {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return HTTPBody(data: data)
    }
}
