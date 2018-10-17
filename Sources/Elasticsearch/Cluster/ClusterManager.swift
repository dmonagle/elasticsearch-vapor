//
//  ClusterManager.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

/// Manages the list and health of elasticsearch nodes
public class ESClusterManager {
    var selector : ElasticsearchNodeSelector = RoundRobinSelector()
    var length : UInt32 { return UInt32(aliveNodes.count) }
    var aliveNodes : [ESNode] { return nodes.filter({ $0.isAlive }) }
    var deadNodes : [ESNode] { return nodes.filter({ !$0.isAlive }).sorted(by: { $0.deadSince! < $1.deadSince! })}
    
    public private(set) var nodes : Set<ESNode> = []
    
    public init() {
    }
    
    public init(config: ElasticsearchConfig) {
        for url in config.seedURLs {
            let node = ESNode(url: url, baseDeadTime: config.baseConnectionDeadTime)
            self.add(node: node)
        }
    }
    
    /**
     * Returns a connection.
     *
     * If there are no alive connections, resurrects a connection with least failures.
     *
     */
    public func nextNode() -> ESNode? {
        if (nodes.isEmpty) { return nil }
        resurrectConnections()
        
        if (aliveNodes.count == 0) {
            deadNodes[0].makeAlive()
        }
        
        return aliveNodes[Int(selector.selectNodeNumber(from: self))]
    }
    
    /// Resurrects all eligable connections
    internal func resurrectConnections() {
        for connection in deadNodes {
            if (connection.isResurrectable) {
                connection.makeAlive()
            }
            else {
                // As these are sorted by deadSince, as soon as we hit one that's not resurrectable we can break
                break
            }
        }
    }
    
    /// Adds a connection to the pool.
    public func add(node: ESNode) {
        nodes.insert(node)
    }
}
