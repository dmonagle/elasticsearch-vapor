//
//  ElasticsearchClient.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import HTTP
import Dispatch

/// An Elasticsearch client.
public final class ElasticsearchClient: DatabaseConnection, BasicWorker, ESIndexer {
    public var jsonEncoder: JSONEncoder = Database.jsonEncoder
    
    // MARK: ESIndexer
    public typealias Database = ElasticsearchDatabase
    
    /// See `BasicWorker`.
    public var eventLoop: EventLoop
    
    /// See `DatabaseConnection`.
    public var isClosed: Bool
    
    /// See `Extendable`.
    public var extend: Extend

    /// See `LogSupporting`.
    public var logger: DatabaseLogger?

    /// Currently executing `send(...)` promise.
    private var currentSend: Promise<Void>?
    
    private var node: ESNode
    private var config: ElasticsearchClientConfig
    private var httpClient: Future<HTTPClient>!
    
    /// Connects to an Elasticsearch server using a HTTPClient.
    public static func connect(
        on worker: Worker,
        node: ESNode,
        config: ElasticsearchClientConfig = ElasticsearchClientConfig(),
        onError: @escaping (Error) -> Void
        ) -> Future<ElasticsearchClient> {
        let client = self.init(eventLoop: worker.eventLoop, node: node, config: config)
        return Future.map(on: worker, { client })
    }

    /// Creates a new Elasticsearch client on the provided data source and sink.
    init(eventLoop: EventLoop, node: ESNode, config: ElasticsearchClientConfig = ElasticsearchClientConfig()) {
        self.eventLoop = eventLoop
        self.config = config
        self.node = node

        self.extend = [:]
        self.isClosed = false
        
        
        httpClient = HTTPClient.connect(url: node.url, connectTimeout: TimeAmount.seconds(Int(config.requestTimeout)), on: eventLoop)
    }

    public func close() {
        self.isClosed = true
        let _ = try! self.httpClient.map { client in
            return client.close()
        }.wait()
    }
    
    public func request(method: HTTPMethod, path pathArray: ESArray = [], query: ESDictionary = [:], requestBody: HTTPBody = HTTPBody.empty) -> Future<HTTPResponse> {
        return httpClient.flatMap { client in
            let path : String
            do {
                path = try pathArray.esPathify()
            }
            catch {
                return self.httpClient.eventLoop.future(error: error)
            }
            let pathWithQuery = "\(path)?\(query.queryString())"
            var request = HTTPRequest(method: method, url: pathWithQuery)
            request.headers.add(name: "Content-Type", value: "application/json")
            self.logger?.record(query: "\(method) \(pathWithQuery)")
            if let bodyCount = requestBody.count {
                if bodyCount > 0 {
                    request.body = requestBody
                    // As there is an issue sending a body with a GET, we take the advice of Elasticsearch and change the request to a .POST
                    //
                    // From https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html
                    // Both HTTP GET and HTTP POST can be used to execute search with body. Since not all clients support GET with body, POST is allowed as well.
                    if (method == .GET) {
                        request.method = .POST
                    }
                    
                    if bodyCount <= 1024 {
                        self.logger?.record(query: "Request body:\n\(requestBody)")
                    }
                }
            }
            return client.send(request)
        }
    }

    
    /// Returns an ESIndexName with the default prefix if it doesn't have one explicitly set
    ///
    /// - Parameter indexName: The ESIndexName to be prefixed
    /// - Returns: An ESIndexName with the prefix set appropriately
    public func prefix(_ indexName: ESIndexName?) -> ESIndexName? {
        guard let indexName = indexName else { return nil }
        if indexName.prefix == nil { return ESIndexName(prefix: self.config.defaultPrefix, indexName.name) }
        return indexName
    }
    
    public func makePath(index: ESIndexName? = nil, type: String? = nil, for action: String? = nil) -> ESArray {
        let path : ESArray = [self.prefix(index)?.description ?? "_all", type, action]
        return path
    }

    // MARK: JSON
    
    /// Decodes asynchronously on the global queue
    func decodeAsync<ResponseType>(body: HTTPBody) -> Future<ResponseType> where ResponseType : Decodable {
        let promise = self.eventLoop.newPromise(ResponseType.self)
        DispatchQueue.global().async {
            do {
                let result : ResponseType = try self.decode(body: body)
                
                promise.succeed(result: result)
            }
            catch {
                promise.fail(error: error)
            }
        }
        return promise.futureResult
    }
    
    func decode<ResponseType>(body: HTTPBody) throws -> ResponseType where ResponseType : Decodable {
        guard let data = body.data else { throw ESApiError.noBodyData(body) }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(ElasticsearchDatabase.dateEncodingFormat)

        do {
            let response = try decoder.decode(ResponseType.self, from: data)
            return response
        }
        catch {
            throw ESApiError.couldNotDecodeJsonBody(error, body)
        }
    }

}

// MARK: - Config
public struct ElasticsearchConfig: Codable {
    public var seedURLs : Set<URL>
    public var resurrectAfter : Int /// Seconds after which to ressurect a dead host
    public var baseConnectionDeadTime : TimeInterval /// The base time a host stays marked as dead for
    public var clientConfig : ElasticsearchClientConfig
    
    public init(seedURLs : Set<URL> = [], resurrectAfter : Int = 60, baseConnectionDeadTime : TimeInterval = 60, maxRetries : Int = 2, requestTimeout : TimeInterval = 15) {
        self.seedURLs = seedURLs
        // If no URL is specified, attempt to go with elasticsearch:9200
        if seedURLs.isEmpty {
            if let url = URL(string: "http://elasticsearch:9200") {
                self.seedURLs.insert(url)
            }
        }
        self.resurrectAfter = resurrectAfter
        self.baseConnectionDeadTime = baseConnectionDeadTime
        self.clientConfig = ElasticsearchClientConfig(maxRetries: maxRetries, requestTimeout: requestTimeout)
    }
}

public struct ElasticsearchClientConfig: Codable {
    public var maxRetries : Int /// If 0, requests will not be retried
    public var requestTimeout : TimeInterval /// Timeout for each HTTPRequest
    public var defaultPrefix : String? = nil /// The default prefix to add to an indexName

    public init(maxRetries : Int = 2, requestTimeout : TimeInterval = 15) {
        self.maxRetries = maxRetries
        self.requestTimeout = requestTimeout
    }
}
