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

}
