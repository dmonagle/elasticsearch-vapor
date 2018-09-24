//
//  ApiError.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 21/9/18.
//

import Foundation

enum ESApiError : Error {
    case couldNotDecodeJsonBody(HTTPBody)
}
