//
//  Indices.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 25/9/18.
//

extension ElasticsearchClient {
    public func exists(index: ESIndexName, query: ESDictionary = [:]) -> Future<Bool> {
        let path : ESArray = [self.prefix(index)?.description]
        return request(method: .HEAD, path: path, query: query).map(to: Bool.self) { response in
            return response.status == .ok
        }
    }

    public func create(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description]
        return request(method: .PUT, path: path, query: query, requestBody: body)
    }

    public func ensure(index: ESIndexName, type: String? = nil, query: ESDictionary = [:], body: HTTPBody) -> Future<Bool> {
        return exists(index: index).flatMap { exists in
            if !exists {
                return self.create(index: index, body: body).map { response in
                    return true
                }
            }
            return self.future(false) // Return false as the index already existed
        }
    }

    public func delete(index: ESIndexName, query: ESDictionary = [:]) -> Future<HTTPResponse> {
        let path : ESArray = [self.prefix(index)?.description]
        return request(method: .DELETE, path: path, query: query)
    }
}
