//
//  ESNode.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import Foundation
import HTTP

public enum ESNodeError : ElasticsearchError {
    case noAvailableNodes
}

/**
 * Tracks the health of an ESNode
 */
open class ESNode {
    public private(set) var url : URL
    internal var failures = 0
    internal var deadSince : Date?
    internal var baseDeadTime : TimeInterval
    
    public init(url: URL, baseDeadTime: TimeInterval = 60) {
        self.url = url
        self.baseDeadTime = baseDeadTime
    }
    
    convenience init?(string urlString: String, baseDeadTime: TimeInterval = 60) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(url: url)
    }
    
    /// Returns true if the connection has been marked as dead
    open var isDead : Bool {
        return (deadSince != nil) ? true : false
    }
    
    /// Returns true if the connection has not been marked as dead
    open var isAlive : Bool { return !isDead }
    
    /// Returns true if the connection is dead longer than the resurrection timeout
    open var isResurrectable : Bool {
        let currentTime = Date()
        
        if let deadSince = deadSince {
            return currentTime > deadSince + currentTimeout;
        }
        return false
    }
    
    /// Returns what the current resurrection timeout should be
    open var currentTimeout : TimeInterval {
        return baseDeadTime * pow(2.0, Double(failures - 1))
    }
    
    /**
     * Marks this connection as dead, incrementing the `failures` counter and
     * storing the current time as `dead_since`.
     */
    internal func makeDead() {
        deadSince = Date()
        failures += 1
    }
    
    /// Marks this connection as alive, ie. it is eligible to be returned from the pool by the selector.
    internal func makeAlive() {
        deadSince = nil
    }
    
    /// Marks this connection as healthy, ie. a request has been successfully performed with it.
    internal func makeHealthy() {
        makeAlive()
        failures = 0
    }
    
    /// Resurrects the connection if it is eligiable
    internal func resurrect(force: Bool = false) {
        if (isResurrectable || force) { makeAlive() }
    }
}

extension ESNode : CustomStringConvertible {
    open var description: String {
        var description = "<ESNode host: \(url) "
        if let deadSince = deadSince {
            description += "dead since \(deadSince)"
        }
        else {
            description += "alive"
        }
        description += ">"
        return description
    }
}

extension ESNode : Hashable, Equatable {
    // Satisfy the Hashable Protocol
    open var hashValue: Int {
        return (url.absoluteString.hashValue)
    }
    
    // Satisfy the Equatable Protocol
    public static func == (lhs: ESNode, rhs: ESNode) -> Bool {
        return lhs.url == rhs.url
    }
}
