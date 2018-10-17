//
//  NodeSelection.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import Foundation

protocol ElasticsearchNodeSelector {
    mutating func selectNodeNumber(from manager: ESClusterManager) -> UInt32
}

struct RoundRobinSelector : ElasticsearchNodeSelector {
    private var _current : UInt32 = 0
    
    mutating func selectNodeNumber(from manager: ESClusterManager) -> UInt32 {
        let result : UInt32
        if (_current >= manager.length) {
            _current = 0
            result = 0
        }
        else {
            result = _current
            _current += 1
        }
        
        return result
    }
}



