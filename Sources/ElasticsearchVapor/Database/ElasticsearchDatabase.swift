//
//  ElasticsearchDatabase.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

public final class ElasticsearchDatabase: Database {
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
