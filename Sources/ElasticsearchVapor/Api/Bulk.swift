//
//  Bulk.swift
//  Elasticsearch
//
//  Created by David Monagle on 23/7/17.
//

import Foundation

public enum ESBulkError : ElasticsearchError {
    case noId
    case noData
    case jsonEncodingFailed(String)
}

public enum ESBulkAction: String {
    case index /// Will add or replace a document as necessary
    case create /// Will fail if a document with the same index and type exists already
    case delete /// Does not expect a source on the following line, and has the same semantics as the standard delete API
    case update /// Expects that the partial doc, upsert and script and its options are specified on the next line. Fails if it doesn't exist.
}

public struct ESBulkActionRequest {
    public static let NewLine: UInt8 = 0x0A

    var action : ESBulkAction
    var meta: ESBulkMeta
    
    var data: Data
    
    func encodedPayload(with encoder: JSONEncoder) throws -> Data {
        var payloadData = Data()
        guard let metaJson = try String(data: encoder.encode(meta), encoding: .utf8) else { throw ESBulkError.jsonEncodingFailed("")}
        
        let actionDataString = "{\"\(action.rawValue)\":\(metaJson)\n"
        guard let actionData = actionDataString.data(using: .utf8) else { throw ESBulkError.jsonEncodingFailed(actionDataString) }
        payloadData.append(actionData)
        payloadData.append(data)
        if payloadData.last != ESBulkActionRequest.NewLine { payloadData.append(ESBulkActionRequest.NewLine)}

        return payloadData
    }
}

public struct ESBulkMeta : Encodable {
    var _index : ESIndexName?
    var _type : String?
    var _id : String?
    var _parent : String?
}

public extension ElasticsearchClient {
    public func bulk(index: ESIndexName? = nil, type: String? = nil, body: HTTPBody, query: ESDictionary = [:]) throws -> Future<Void> {
        let index = self.prefix(index)
        let path = [index?.description, type, "_bulk"]
        let response = self.request(method: .POST, path: path, query: query, requestBody: body)
        return response.map { response in
//            print(response.body)
        }.transform(to: ())
    }
}

public class ESBulkProxy {
    static let defaultThreshold = 12_000_000 // Default to max 12MB requests
    
    private var client : ElasticsearchClient
    private var buffer : Data
    public var threshhold: Int = defaultThreshold
    
    public var defaultIndex: ESIndexName?
    public var defaultType: String?

    public private(set) var totalRecords: Int
    public private(set) var recordsInBuffer: Int
    
    public init(client: ElasticsearchClient, threshold: Int? = nil, defaultIndex: ESIndexName? = nil, defaultType: String? = nil) {
        self.defaultIndex = defaultIndex
        self.defaultType = defaultType
        self.client = client

        if let threshold = threshold { self.threshhold = threshold }
        totalRecords = 0

        buffer = Data()
        buffer.reserveCapacity(threshhold)
        recordsInBuffer = 0
    }
    
    deinit {
        let _ = try? flush()
    }
    
    private func resetBuffer() {
        buffer = Data()
        buffer.reserveCapacity(threshhold)
        recordsInBuffer = 0
    }
    
    private func ensureBufferEndsWithNewline() {
        if buffer.last != ESBulkActionRequest.NewLine { buffer.append(ESBulkActionRequest.NewLine)}
    }
    
    public func flush() throws -> Future<Void> {
        guard !buffer.isEmpty else { return eventLoop.future() }
        ensureBufferEndsWithNewline()
        client.logger?.record(query: "Flushing Elasticsearch bulk proxy: \(recordsInBuffer) records, \(buffer.count) bytes.")
        let body = HTTPBody(data: buffer)
        return try client.bulk(index: defaultIndex, type: defaultType, body: body).always {
            self.resetBuffer()
        }
    }
    
    internal func append(data: Data) throws -> Future<Void> {
        let returnFuture : Future<Void>
        
        // If a single input doesn't fit within the threshold, expand the threshold to allow it
        if data.count > threshhold {
            threshhold = data.count
            buffer.reserveCapacity(threshhold)
        }
        
        // Flush the buffer if the input doesn't fit
        if data.count > (threshhold - buffer.count) {
            returnFuture = try flush()
        }
        else {
            returnFuture = eventLoop.future()
        }
        
        return returnFuture.always {
            self.buffer.append(data)
            self.recordsInBuffer += 1
            self.totalRecords += 1
        }
    }

    public func append(_ action: ESBulkAction, index: ESIndexName, type: String, id: String? = nil, parentId: String? = nil, data: Data) throws -> Future<Void> {
        var bulkMeta = ESBulkMeta(_index: client.prefix(index), _type: type, _id: id, _parent: parentId)
        
        // If the index is the same as the defaultIndex, remove it from the bulkData
        if let defaultIndex = defaultIndex {
            if client.prefix(defaultIndex)?.description == bulkMeta._index!.description {
                bulkMeta._index = nil
            }
        }
        
        // Remove the type on the bulkData if it's the same as the defaultType
        if type == defaultType {
            bulkMeta._type = nil
        }
        
        let bulkData = ESBulkActionRequest(action: action, meta: bulkMeta, data: data)
        
        return try append(data: bulkData.encodedPayload(with: jsonEncoder))
    }
    
    public func append<Indexable>(_ action: ESBulkAction, _ indexable : Indexable) throws -> Future<Void> where Indexable : ESIndexable {
        let data = try client.encodeJson(indexable)
        return try append(action, index: Indexable.esIndex, type: Indexable.esType, id: indexable.esId, parentId: indexable.esParentId, data: data)
    }
}

extension ESBulkProxy : ESIndexer {
    public var jsonEncoder : JSONEncoder {
        return client.jsonEncoder
    }
    
    public var eventLoop: EventLoop {
        return client.eventLoop
    }
    
    public static var dateEncodingFormat: DateFormatter {
        return ElasticsearchClient.dateEncodingFormat
    }

    public func index(index: ESIndexName, type: String, id: String?, body: HTTPBody, query: ESDictionary) throws -> EventLoopFuture<Void> {
        guard let data = body.data else { throw ESBulkError.noData }
        return try append(.index, index: index, type: type, id: id, data: data)
    }

    public func delete(index: ESIndexName, type: String, id: String?, query: ESDictionary) -> EventLoopFuture<Void> {
        return client.delete(index: index, type: type, id: id, query: query)
    }
}
