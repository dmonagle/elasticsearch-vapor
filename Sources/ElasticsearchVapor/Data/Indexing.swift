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
public struct ESIndexName : CustomStringConvertible {
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
public protocol ESIndexable : Codable  where ModelData : Codable {
    associatedtype ModelData
    static var esIndex : ESIndexName { get }
    static var esType : String { get }

    var esId: String? { get }
    var esParentId: String? { get }
    
    var data : ModelData { get }
}

/// Default implementations
extension ESIndexable {
    public var esParentId: String? { get { return nil } }
}

/**
 Allows the indexing or deleting of ESIndexable documents
 */
public protocol ESIndexer {
    func index(index: ESIndexName, type: String, id: String?, body: String, query: ESDictionary, on worker: Worker) -> Future<Void>
    func flush(on container: Container) -> Future<Void>
    static var dateEncodingFormat : DateFormatter { get }

}

public extension ESIndexer {
    func index<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary, on worker: Worker) -> Future<Void> where IndexableModel : ESIndexable {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateEncodingFormat)
        do {
            let data = try encoder.encode(indexable.data)
            guard let body = String(data: data, encoding: .utf8) else { throw ESIndexingError.errorCreatingUTF8String(data) }
            return self.index(index: IndexableModel.esIndex, type: IndexableModel.esType, id: indexable.esId, body: body, query: query, on: worker)
        } catch {
            return worker.future(error: error)
        }
    }
    func delete<IndexableModel>(_ indexable: IndexableModel) throws {
    }
}

extension ElasticsearchClient : ESIndexer {
    public static var dateEncodingFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    public func index(index: ESIndexName, type: String, id: String?, body: String, query: ESDictionary, on worker: Worker) -> Future<Void> {
        let method : HTTPMethod = (id != nil ? .PUT : .POST)
        
        let path = [self.prefix(index).description, type, id]
        
        return self.request(method: method, path: path, query: query, requestBody: body).transform(to: ())
    }
    
    public func index<IndexableModel>(_ indexable: IndexableModel, query: ESDictionary) -> Future<Void> where IndexableModel : ESIndexable {
        return self.index(indexable, query: query, on: self.eventLoop)
    }
    public func delete<IndexableModel>(_ indexable: IndexableModel) throws {
    }
    
    public func flush(on container: Container) -> Future<Void> {
        return container.future()
    }
}
