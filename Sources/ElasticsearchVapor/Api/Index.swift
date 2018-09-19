//
//  Index.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 19/9/18.
//

import Foundation
import HTTP

extension ElasticsearchClient : ESIndexer {
    public static var dateEncodingFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    public func index(index: ESIndexName, type: String, id: String?, body: HTTPBody, query: ESDictionary) -> Future<Void> {
        let method : HTTPMethod = (id != nil ? .PUT : .POST)
        
        let path = [self.prefix(index)?.description, type, id]
        
        return self.request(method: method, path: path, query: query, requestBody: body).transform(to: ())
    }
    
    public func delete<IndexableModel>(_ indexable: IndexableModel) throws {
    }
    
    public func flush(on container: Container) -> Future<Void> {
        return container.future()
    }
}
