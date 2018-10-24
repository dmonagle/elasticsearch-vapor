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

public protocol ESMappable : ESIndexable {
    static var esMappings : [String: Any] { get }
}

public extension ElasticsearchClient {
    public func create(index mappable: ESMappable.Type, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<HTTPResponse> {
        let body : [String: Any] = [
            "mappings": mappable.esMappings
        ]
        let httpBody = try encodeJsonBody(dictionary: body)
        return create(index: mappable.esIndex, body: httpBody)
    }
    
    public func ensure(index mappable: ESMappable.Type, type: String? = nil, query: ESDictionary = [:]) throws -> Future<Bool> {
        let body : [String: Any] = [
            "mappings": mappable.esMappings
        ]
        let httpBody = try encodeJsonBody(dictionary: body)
        return ensure(index: mappable.esIndex, query: query, body: httpBody)
    }

    public func delete(index mappable: ESMappable.Type, type: String? = nil, query: ESDictionary = [:]) throws -> Future<HTTPResponse> {
        return delete(index: mappable.esIndex, query: query)
    }
}

/**
 Allows the indexing or deleting of ESIndexable documents
 */
public protocol ESIndexer {
    var eventLoop : EventLoop { get }
    func index(index: ESIndexName, type: String, id: String?, body: HTTPBody, query: ESDictionary) throws -> Future<HTTPResponse?>
    func delete(index: ESIndexName, type: String, id: String?, query: ESDictionary) -> Future<HTTPResponse?>
    func flush(query: ESDictionary) throws -> Future<HTTPResponse?>
    var jsonEncoder : JSONEncoder { get }
}

public extension ESIndexer {
    func index<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary = [:]) throws -> Future<HTTPResponse?> where IndexableModel : ESIndexable {
        do {
            let body = try HTTPBody(data: self.encodeJson(indexable))
            return try self.index(index: IndexableModel.esIndex, type: IndexableModel.esType, id: indexable.esId, body: body, query: query)
        } catch {
            return self.eventLoop.future(error: error)
        }
    }
    
    func delete<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary = [:]) throws -> Future<HTTPResponse?> where IndexableModel : ESIndexable {
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
