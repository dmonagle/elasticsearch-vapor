//
//  Search.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 25/9/18.
//

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
        //public var sort : ESArray?
    }
    public class HitResult : Codable {
        public var total: UInt
        public var max_score: UInt?
        public var hits : [HitData]
    }
    
    public var took : Int
    public var timed_out : Bool
    public var _scroll_id : String?
    public var _shards : ShardResult
    public var hits : HitResult
}

public extension ElasticsearchClient {
    public func search<Model>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponse<Model>> {
        let path : ESArray = [self.prefix(index)?.description, type, "_search"]
        return request(method: .POST, path: path, query: query, requestBody: body).map(to: ESSearchResponse.self) { httpResponse in
            return try self.decode(body: httpResponse.body)
        }
    }
}
