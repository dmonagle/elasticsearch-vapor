//
//  ElasticsearchDatabase+QuerySupporting.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 17/10/18.
//

import Fluent
import Elasticsearch
import SwiftyJSON

public enum ElasticsearchQueryAction {
    case insert
    case update
    case delete
}

//extension ElasticsearchDatabase : QuerySupporting {
//    public typealias Query = JSON
//    public typealias Output = JSON
//    public typealias QueryAction = ElasticsearchQueryAction
//    public typealias QueryAggregate = JSON
//    public typealias QueryData = JSON
//    public typealias QueryField = JSON
//    public typealias QueryFilterMethod = JSON
//    public typealias QueryFilterValue = JSON
//    public typealias QueryFilter = JSON
//    public typealias QueryFilterRelation = JSON
//    public typealias QueryKey = JSON
//    public typealias QuerySort = JSON
//    public typealias QuerySortDirection = JSON
//
//    public static func queryExecute(_ query: JSON, on conn: ElasticsearchClient, into handler: @escaping (JSON, ElasticsearchClient) throws -> ()) -> EventLoopFuture<Void> {
//        return conn.future()
//    }
//
//    public static func queryDecode<D>(_ output: JSON, entity: String, as decodable: D.Type, on conn: ElasticsearchClient) -> EventLoopFuture<D> where D : Decodable {
//
//        json
//    }
//
//    public static func queryEncode<E>(_ encodable: E, entity: String) throws -> JSON where E : Encodable {
//        <#code#>
//    }
//
//    public static func queryActionApply(_ action: ElasticsearchQueryAction, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func queryDataSet<E>(_ field: JSON, to data: E, on query: inout JSON) where E : Encodable {
//        <#code#>
//    }
//
//    public static func queryDataApply(_ data: JSON, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func queryFilters(for query: JSON) -> [JSON] {
//        <#code#>
//    }
//
//    public static func queryFilterApply(_ filter: JSON, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func queryDefaultFilterRelation(_ relation: JSON, on: inout JSON) {
//        <#code#>
//    }
//
//    public static func queryKeyApply(_ key: JSON, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func querySortApply(_ sort: JSON, to query: inout JSON) {
//        <#code#>
//    }
//
//    public static func query(_ entity: String) -> JSON {
//        return JSON()
//    }
//
//    public static func queryEntity(for query: JSON) -> String {
//        return ""
//    }
//
//    public static func queryExecute(_ query: Encodable, on conn: ElasticsearchClient, into handler: @escaping (Decodable, ElasticsearchClient) throws -> ()) -> EventLoopFuture<Void> {
//        return conn.future()
//    }
//
//    public static func modelEvent<M>(event: ModelEvent, model: M, on conn: ElasticsearchClient) -> EventLoopFuture<M> where ElasticsearchDatabase == M.Database, M : Model {
//        <#code#>
//    }
//
//    public static var queryActionCreate: ElasticsearchQueryAction {
//        <#code#>
//    }
//
//    public static var queryActionRead: ElasticsearchQueryAction {
//        <#code#>
//    }
//
//    public static var queryActionUpdate: ElasticsearchQueryAction {
//        <#code#>
//    }
//
//    public static var queryActionDelete: ElasticsearchQueryAction {
//        <#code#>
//    }
//
//    public static func queryActionIsCreate(_ action: ElasticsearchQueryAction) -> Bool {
//        <#code#>
//    }
//
//    public static func queryActionApply(_ action: ElasticsearchQueryAction, to query: inout Encodable) {
//        <#code#>
//    }
//
//    public static var queryAggregateCount: JSON {
//        <#code#>
//    }
//
//    public static var queryAggregateSum: JSON {
//        <#code#>
//    }
//
//    public static var queryAggregateAverage: JSON {
//        <#code#>
//    }
//
//    public static var queryAggregateMinimum: JSON {
//        <#code#>
//    }
//
//    public static var queryAggregateMaximum: JSON {
//        <#code#>
//    }
//
//    public static func queryDataSet<E>(_ field: JSON, to data: E, on query: inout Encodable) where E : Encodable {
//        <#code#>
//    }
//
//    public static func queryDataApply(_ data: Encodable, to query: inout Encodable) {
//        <#code#>
//    }
//
//    public static func queryField(_ property: FluentProperty) -> JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodEqual: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodNotEqual: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodGreaterThan: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodLessThan: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodGreaterThanOrEqual: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodLessThanOrEqual: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodInSubset: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterMethodNotInSubset: JSON {
//        <#code#>
//    }
//
//    public static func queryFilterValue<E>(_ encodables: [E]) -> JSON where E : Encodable {
//        <#code#>
//    }
//
//    public static var queryFilterValueNil: JSON {
//        <#code#>
//    }
//
//    public static func queryFilter(_ field: JSON, _ method: JSON, _ value: JSON) -> JSON {
//        <#code#>
//    }
//
//    public static var queryFilterRelationAnd: JSON {
//        <#code#>
//    }
//
//    public static var queryFilterRelationOr: JSON {
//        <#code#>
//    }
//
//    public static func queryDefaultFilterRelation(_ relation: JSON, on: inout Encodable) {
//        <#code#>
//    }
//
//    public static func queryFilterGroup(_ relation: JSON, _ filters: [JSON]) -> JSON {
//        <#code#>
//    }
//
//    public static var queryKeyAll: JSON {
//        <#code#>
//    }
//
//    public static func queryAggregate(_ aggregate: JSON, _ fields: [JSON]) -> JSON {
//        <#code#>
//    }
//
//    public static func queryKey(_ field: JSON) -> JSON {
//        <#code#>
//    }
//
//    public static func queryKeyApply(_ key: JSON, to query: inout Encodable) {
//        <#code#>
//    }
//
//    public static func queryRangeApply(lower: Int, upper: Int?, to query: inout Encodable) {
//        <#code#>
//    }
//
//    public static func querySort(_ field: JSON, _ direction: JSON) -> JSON {
//        return JSON()
//    }
//
//    public static var querySortDirectionAscending: JSON = JSON()
//    public static var querySortDirectionDescending: JSON = JSON()
//
//    public static func querySortApply(_ sort: JSON, to query: inout Encodable) {
//    }
//}
