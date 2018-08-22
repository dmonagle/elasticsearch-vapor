//
//  Transport.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import Foundation
import HTTP

/// Contains the settings used by a Transport object
public struct TransportSettings {
    public var retryOnFailure : Bool
    public var reloadAfter : Int /// Requests
    public var resurrectAfter : Int /// Seconds
    public var maxRetries : Int /// Requests
    public var baseConnectionTimeout : TimeInterval /// The base time a connection stays dead for
    public var requestTimeout : TimeInterval /// Timeout for each HTTPRequest

    public init(retryOnFailure : Bool = true, reloadAfter : Int = 1000, resurrectAfter : Int = 60, maxRetries : Int = 3, baseConnectionTimeout : TimeInterval = 60, requestTimeout : TimeInterval = 15) {
        self.retryOnFailure = retryOnFailure
        self.reloadAfter = reloadAfter
        self.resurrectAfter = resurrectAfter
        self.maxRetries = maxRetries
        self.baseConnectionTimeout = baseConnectionTimeout
        self.requestTimeout = requestTimeout
    }
}

open class ElasticsearchLLClient {
    internal var clusterManager : ESClusterManager = ESClusterManager()
//    public var logger : Logger? = nil
  
    internal var nodes : Set<URL> = []
    internal var connectionCounter : Int = 0
    internal var settings : TransportSettings
    
    public init(settings: TransportSettings? = nil) {
        if let s = settings {
            self.settings = s
        }
        else {
            self.settings = TransportSettings()
        }
        self.clusterManager = ESClusterManager()
    }

    public func addConnection(_ connection: ESNode) throws {
        clusterManager.add(node: connection)
    }
    
    public func addHost(url: URL) throws {
        if !nodes.contains(url) {
            nodes.insert(url)
            let connection = ESNode(url: url, baseDeadTime: settings.baseConnectionTimeout)
            try addConnection(connection)
        }
    }
    
    public func addHost(string: String) throws {
        if let url = URL(string: string) {
            try addHost(url: url)
        }
    }
    
    internal func buildConnections() {
        clusterManager = ESClusterManager()
        connectionCounter = 0
        for host in nodes {
            try? addHost(url: host)
        }
    }
    
    /**
     Returns a connection from the connection pool by delegating to Collection.
     
     Resurrects dead connection if the resurrectAfter timeout has passed.
     Increments the counter and performs connection reloading if the `reload_connections` option is set.
     
     - returns: ESNode
     */
    public func getConnection() -> ESNode? {
        if (clusterManager.length == 0) { buildConnections() }
        // Reload connections if we've hit the reloadAfter
        if (settings.reloadAfter != 0 && (connectionCounter >= settings.reloadAfter)) {
            //sniffConnections()
        }
        
        if let connection = clusterManager.nextNode() {
            connectionCounter += 1
            
            
            return connection;
        }
        
        return nil
    }

    /// Attempts to resurrect all dead connections
    internal func resurrectDeadConnections(force: Bool = false) {
        for connection in clusterManager.deadNodes {
            connection.resurrect(force: force);
        }
    }

}
