//
//  ElasticsearchDatabase.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

public final class ElasticsearchDatabase: Database {
    public static var dateEncodingFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    public static var jsonEncoder : JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateEncodingFormat)
        return encoder
    }()
    
    public static var jsonDecoder : JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateEncodingFormat)
        return decoder
    }()
    
    /// This client's configuration.
    public let config: ElasticsearchConfig
    
    /// Creates a new `ElasticsearchDatabase`.
    public init(config: ElasticsearchConfig = ElasticsearchConfig()) throws {
        self.config = config
        self.clusterManager = ESClusterManager(config: config)
    }
    
    /// See `Database`.
    public func newConnection(on worker: Worker) -> EventLoopFuture<ElasticsearchClient> {
        guard let node = clusterManager.nextNode() else {
            return worker.future(error: ESNodeError.noAvailableNodes)
        }
        return ElasticsearchClient.connect(
            on: worker,
            node: node,
            config: config.clientConfig
        ) { error in
            print("[Elasticsearch] \(error)")
        }
    }
    
    // MARK: - Cluster Management
    private var clusterManager : ESClusterManager

    // MARK: - JSON
    
    /// Decodes asynchronously on the global queue
    static func decode<ResponseType>(body: HTTPBody) throws -> ResponseType where ResponseType : Decodable {
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

extension ElasticsearchDatabase : LogSupporting {
    public static func enableLogging(_ logger: DatabaseLogger, on conn: ElasticsearchClient) {
        conn.logger = logger
    }
    
}

public extension DatabaseIdentifier {
    /// Default identifier for `ElasticsearchDatabase`.
    public static var elasticsearch: DatabaseIdentifier<ElasticsearchDatabase> {
        return .init("elasticsearch")
    }
}
