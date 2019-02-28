//
//  Scroll.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 20/9/18.
//

import Foundation

extension ElasticsearchClient {
    public func scroll(query: ESDictionary) -> Future<HTTPResponse> {
        let path = ["_search", "scroll"]
        
        return request(method: .GET, path: path, query: query)
    }
    
    public func scroll(id: String, query: ESDictionary = [:]) -> Future<HTTPResponse> {
        var query = query
        query["scroll_id"] = id
        return scroll(query: query)
    }
    

    public func scrollAndDecode<Model>(query: ESDictionary) -> Future<ESSearchResponse<Model>> {
        let path = ["_search", "scroll"]
        
        return request(method: .GET, path: path, query: query).flatMap { httpResponse in
            return self.decodeAsync(body: httpResponse.body)
        }
    }
    
    public func scrollAndDecode<Model>(id: String, query: ESDictionary = [:]) -> Future<ESSearchResponse<Model>> {
        var query = query
        query["scroll_id"] = id
        return scrollAndDecode(query: query)
    }

    public func deleteScroll(id: String, query: ESDictionary = [:]) -> Future<HTTPResponse> {
        var query = query
        let path = ["_search", "scroll"]
        query["scroll_id"] = id
        return request(method: .DELETE, path: path, query: query)
    }
}

extension ElasticsearchClient {
    public func scrollSearch<Model>(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody, scrollTimeout: String = "1m", _ process: @escaping (ESSearchResponse<Model>) -> Future<Void>) throws -> Future<Void> {
        var scrollId : String?
        func iterateScroll<T>(response: ESSearchResponse<T>, _ process: @escaping (ESSearchResponse<T>) -> Future<Void>) -> Future<Void> {
            // we got a partial result, let's check what it is
            if response.hits.hits.count > 0 {
                return process(response).then { v in
                    // Store the scroll_id if it was returned
                    if let id = response._scroll_id {
                        scrollId = id
                    }
                    guard let id = scrollId else { return self.eventLoop.future(error: ESParameterError.requiredParameterIsEmpty("_scroll_id"))}
                    let query : ESDictionary = ["scroll": scrollTimeout]
                    return self.scrollAndDecode(id: id, query: query).then { searchResult in
                        return iterateScroll(response: searchResult, process)
                    }
                }
            } else {
                // Scroll should be exhausted
                return eventLoop.newSucceededFuture(result: ())
            }
        }
        
        var scrollQuery = query
        scrollQuery["scroll"] = scrollTimeout
        return try self.search(index: index, type: type, query: scrollQuery, body: body).then { searchResult in
            return iterateScroll(response: searchResult) { result in
                return process(result)
            }
        }.then {
            if let id = scrollId {
                return self.deleteScroll(id: id).transform(to: ())
            }
            return self.eventLoop.future()
        }
    }
}

extension ElasticsearchClient {
    public func scrollSearchPB(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody, scrollTimeout: String = "1m", _ process: @escaping (ElasticsearchSearchResponse) -> Future<Void>) throws -> Future<Void> {
        var scrollId : String?
        @discardableResult func iterateScroll(response: ElasticsearchSearchResponse, _ process: @escaping (ElasticsearchSearchResponse) -> Future<Void>) -> Future<Void> {
            // we got a partial result, let's check what it is
            if response.hits.hits.count > 0 {
                return process(response).flatMap { v in
                    // Store the scroll_id if it was returned
                    if !response.scrollID.isEmpty {
                        scrollId = response.scrollID
                    }
                    guard let id = scrollId else { return self.eventLoop.future(error: ESParameterError.requiredParameterIsEmpty("_scroll_id"))}
                    let query : ESDictionary = ["scroll": scrollTimeout]
                    return self.scroll(id: id, query: query).flatMap { httpResponse in
                        let searchResult = try ElasticsearchSearchResponse(jsonUTF8Data: httpResponse.body.data ?? Data())
                        return iterateScroll(response: searchResult, process)
                    }
                }
            } else {
                // Scroll should be exhausted
                return eventLoop.newSucceededFuture(result: ())
            }
        }
        
        var scrollQuery = query
        scrollQuery["scroll"] = scrollTimeout
        return try self.search(index: index, type: type, query: scrollQuery, body: body).flatMap { httpResponse in
            let searchResult = try ElasticsearchSearchResponse(jsonUTF8Data: httpResponse.body.data ?? Data())
            return iterateScroll(response: searchResult) { result in
                return process(result)
            }
        }.then {
            if let id = scrollId {
                return self.deleteScroll(id: id).transform(to: ())
            }
            return self.eventLoop.future()
        }
    }
}
