//
//  Search.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 25/9/18.
//

fileprivate struct ElasticsearchCountResponse : Decodable {
    var count : UInt = 0
}

public extension ElasticsearchClient {
    func search(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description, type, "_search"]
        return request(method: .POST, path: path, query: query, requestBody: body)
    }

    func searchPB(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ElasticsearchSearchResponse> {
        return try search(index: index, type: type, query: query, body: body).map { httpResponse in
            let response = try ElasticsearchSearchResponse(jsonString: httpResponse.body.description)
            return response
        }
    }

    func search<Model>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponse<Model>> {
        return try search(index: index, type: type, query: query, body: body).flatMap { httpResponse in
            return self.decodeAsync(body: httpResponse.body)
        }
    }

    func searchAndAggregate<Model, AggType>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<ESSearchResponseWithAggs<Model, AggType>> {
        return try search(index: index, type: type, query: query, body: body).flatMap { httpResponse in
            return self.decodeAsync(body: httpResponse.body)
        }
    }

    func count(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) throws -> Future<UInt> {
        let path : ESArray = [self.prefix(index)?.description, type, "_count"]
        return request(method: .POST, path: path, query: query, requestBody: body).map { response in
            let countResponse : ElasticsearchCountResponse = try self.decode(body: response.body)
            return countResponse.count
        }
    }
}
