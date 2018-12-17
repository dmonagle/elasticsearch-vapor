//
//  SearchResponse.swift
//  RecRegistry
//
//  Created by David Monagle on 10/10/18.
//

import Foundation
import SwiftyJSON

public class NoAggs : Codable {
}

public typealias ESSearchResponse<Model> = ESSearchResponseWithAggs<Model, NoAggs> where Model : Codable

public class ESSearchResponseWithAggs<Model, AggregationType> : Codable where Model : Codable, AggregationType : Codable {
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
        public var _score : Double?
        public var _source : Model
        public var sort : JSON?
    }
    public class HitResult : Codable {
        public var total: UInt
        public var max_score: Double?
        public var hits : [HitData]
    }
    
    public var took : Int
    public var timed_out : Bool
    public var _scroll_id : String?
    public var _shards : ShardResult
    public var hits : HitResult
    public var aggregations : AggregationType?
}

public class ESAggregationResponse<BucketType> : Codable where BucketType : Codable {
    public var doc_count_error_upper_bound : Int
    public var sum_other_doc_count : Int
    public var buckets : [BucketType]
}

public class ESAggregationValue<ValueType> : Codable where ValueType : Codable {
    public var value : ValueType
}
