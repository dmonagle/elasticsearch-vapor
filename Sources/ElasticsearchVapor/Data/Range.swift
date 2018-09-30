//
//  Range.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 30/9/18.
//

// MARK: - Elasticsearch Date Range
public struct ElasticsearchRange<RangeType> : Codable where RangeType : Codable {
    public var gt: RangeType?
    public var gte: RangeType?
    public var lte: RangeType?
    public var lt: RangeType?
    
    public init(gt: RangeType? = nil, gte: RangeType? = nil, lte: RangeType? = nil, lt: RangeType? = nil) {
        self.gt = gt
        self.gte = gte
        self.lte = lte
        self.lt = lt
    }
}

public typealias ElasticsearchDateRange = ElasticsearchRange<Date>
public typealias ElasticsearchIntRange = ElasticsearchRange<Int>
