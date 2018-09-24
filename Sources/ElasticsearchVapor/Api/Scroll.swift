//
//  Scroll.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 20/9/18.
//

import Foundation

extension ElasticsearchClient {
    public func scroll(query: ESDictionary) throws -> Future<HTTPResponse> {
        let path = ["_search", "scroll"]
        
        return request(method: .GET, path: path, query: query)
    }
    
    public func scroll(id: String, query: ESDictionary = [:]) throws -> Future<HTTPResponse> {
        var query = query
        query["scroll_id"] = id
        return try scroll(query: query)
    }
}

