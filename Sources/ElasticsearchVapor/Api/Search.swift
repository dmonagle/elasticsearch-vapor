//
//  Search.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 25/9/18.
//

public extension ElasticsearchClient {
    public func search(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description, type, "_search"]
        return request(method: .POST, path: path, query: query, requestBody: body)
    }

    public func search<Model>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponse<Model>> {
        return try search(index: index, type: type, query: query, body: body).flatMap { httpResponse in
            return self.decodeAsync(body: httpResponse.body)
        }
    }

    public func searchAndAggregate<Model, AggType>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponseWithAggs<Model, AggType>> {
        return try search(index: index, type: type, query: query, body: body).flatMap { httpResponse in
            return self.decodeAsync(body: httpResponse.body)
        }
    }
}
