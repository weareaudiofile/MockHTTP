//
//  MockHTTP.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

private(set) public var ctx: MockingContext?

/// Set the global context to be used for MockHTTP. Due to the nature of how our mock URLProtocol class is registered/deregistered with NSURLProtocol, and how it works internally, it must be stored and used as a global context.
///
/// - parameter context: The global context to be set. You can reset (and disable) mocking by specifying `nil` here.
public func setGlobalContext(_ context: MockingContext?) {
    ctx = context
}

public final class MockingContext {
    private var responseForURL : [URL: URLResponse] = [:]
    private var responseForRequestFilter: [(matcher: (URLRequest) -> (Bool), response: URLResponse)] = []
    private var mockedRequests : [URLRequest] = []
    private let mutex: Mutex

    private let configuration: URLSessionConfiguration?

    public init(configuration: URLSessionConfiguration?) {
        mutex = Mutex(recursive: true)

        Foundation.URLProtocol.registerClass(URLProtocol.self)

        self.configuration = configuration

        if var protoClasses = configuration?.protocolClasses {
            protoClasses = [URLProtocol.self as AnyClass] + protoClasses
            configuration?.protocolClasses = protoClasses
        }
    }

    deinit {
        Foundation.URLProtocol.unregisterClass(URLProtocol.self)

        if let configuration = configuration, var protocols = configuration.protocolClasses {

            let foundIndex = protocols.index { $0 == URLProtocol.self }
            if let indexToRemove = foundIndex {
                protocols.remove(at: indexToRemove)
            }

            configuration.protocolClasses = protocols
        }

    }

    private func withLock<U>(@noescape _ f: (MockingContext) -> U) -> U {
        return mutex.inCriticalSection { f(self) }
    }

    private var _defaultResponse: URLResponse?
    public var defaultResponse: URLResponse? {
        get {
            return withLock { $0._defaultResponse }
        }
        set {
            withLock { $0._defaultResponse = newValue }
        }
    }

    public func requests() -> [URLRequest] {
        return withLock { $0.mockedRequests }
    }

    public func addRequest(_ request: URLRequest) {
        withLock { $0.mockedRequests.append(request) }
    }

    public func removeRequest(_ request: URLRequest) {
        withLock {
            if let findIndex = $0.mockedRequests.index(of: request) {
                $0.mockedRequests.remove(at: findIndex)
            }
        }
    }

    public func registerResponse(_ response: URLResponse, forURL url: URL) {
        withLock { $0.responseForURL[url] = response }
    }

    public func registerResponse(_ response: URLResponse, forRequestFilter requestFilter: (URLRequest) -> (Bool)) {
        withLock { $0.responseForRequestFilter.append((matcher: requestFilter, response: response)) }
    }

    public func responseForURL(_ url: URL) -> URLResponse? {
        return withLock { $0.responseForURL[url] ?? $0.defaultResponse }
    }

    public func responseForRequest(_ request: URLRequest) -> URLResponse? {
        return withLock {
            for obj in $0.responseForRequestFilter {
                if (obj.matcher(request)) {
                    return obj.response
                }
            }
            if let url = request.url {
                return $0.responseForURL(url)
            }

            return nil
        }
    }
}
