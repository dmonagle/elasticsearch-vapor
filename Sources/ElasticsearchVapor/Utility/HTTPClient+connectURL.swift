//
//  HTTPClient+connectURL.swift
//  ElasticsearchVapor
//
//  Created by David Monagle on 22/8/18.
//

import HTTP

public extension URL {
    var httpScheme : HTTPScheme? {
        guard let scheme = self.scheme else { return nil }
        switch scheme {
        case "http":
            return .http
        case "https":
            return .https
        case "ws":
            return .ws
        case "wss":
            return .wss
        default:
            return nil
        }
    }
}

public extension HTTPClient {
    /// Creates a new `HTTPClient` connected over TCP or TLS.
    ///
    ///     let httpRes = HTTPClient.connect(hostname: "vapor.codes", on: ...).map(to: HTTPResponse.self) { client in
    ///         return client.send(...)
    ///     }
    ///
    /// - parameters:
    ///     - url: URL containing the scheme, host and port to connect to
    ///     - connectTimeout: The timeout that will apply to the connection attempt.
    ///     - worker: `Worker` to perform async work on.
    ///     - onError: Optional closure, which fires when a networking error is caught.
    /// - returns: A `Future` containing the connected `HTTPClient`.
    static func connect(
        url: URL,
        connectTimeout: TimeAmount = TimeAmount.seconds(10),
        on worker: Worker,
        onError: @escaping (Error) -> () = { _ in }
        ) -> Future<HTTPClient> {
        
        let scheme = url.httpScheme ?? .http
        let host = url.host ?? "localhost"
        let port = url.port
        
        return self.connect(scheme: scheme, hostname: host, port: port, connectTimeout: connectTimeout, on: worker, onError: onError)
    }
}
