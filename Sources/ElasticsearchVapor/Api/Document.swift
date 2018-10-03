//
//  Document.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 20/9/18.
//

extension ElasticsearchClient {
    // MARK: - Get
    public func get(index: ESIndexName, id: String, type: String? = nil, query: ESDictionary = [:]) throws -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description, type ?? "_all", id]
        return request(method: .GET, path: path, query: query)
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
