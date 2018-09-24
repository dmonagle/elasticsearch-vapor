//
//  Document.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 20/9/18.
//

import Foundation

public class ESSearchResponse<Model> : Codable where Model : Codable {
    public class ShardResult : Codable {
        public var total : UInt
        public var successful: UInt
        public var skipped: UInt
        public var failed: UInt
    }
    public class HitData : Codable {
        public var _index : String
        public var _type : String
        public var _id : String
        public var _score : UInt?
        public var _source : Model
        public var sort : [UInt]
    }
    public class HitResult : Codable {
        public var total: UInt
        public var max_score: UInt?
        public var hits : [HitData]
    }

    public var took : Int
    public var timed_out: Bool
    public var _shards : ShardResult
    public var hits : HitResult
}

extension ElasticsearchClient : ESIndexer {
    public static var dateEncodingFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()

    // MARK: - Get
    public func get(index: ESIndexName, id: String, type: String? = nil, query: ESDictionary = [:]) throws -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description, type ?? "_all", id]
        return request(method: .GET, path: path, query: query)
    }
    
    // MARK: - Search
    
    public func search<Model>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponse<Model>> {
        let path : ESArray = [self.prefix(index)?.description, type, "_search"]
        return request(method: .POST, path: path, query: query, requestBody: body).map(to: ESSearchResponse.self) { httpResponse in
            return try self.decode(body: httpResponse.body)
        }
    }
    
    public func index(index: ESIndexName, type: String, id: String?, body: HTTPBody, query: ESDictionary) -> Future<Void> {
        let method : HTTPMethod = (id != nil ? .PUT : .POST)
        
        let path = [self.prefix(index)?.description, type, id]
        
        return self.request(method: method, path: path, query: query, requestBody: body).transform(to: ())
    }
    
    public func delete(index: ESIndexName, type: String, id: String?, query: ESDictionary) -> EventLoopFuture<Void> {
        let path = [self.prefix(index)?.description, type, id]
        return self.request(method: .DELETE, path: path, query: query).transform(to: ())
    }
    

    public func flush() throws -> EventLoopFuture<Void> {
        return eventLoop.future()
    }
}
