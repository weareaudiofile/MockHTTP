//
//  MockHTTP.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

private(set) public var ctx: MockingContext?

/// Set the global context to be used for MockHTTP. Due to the nature of how our MockURLProtocol class is registered/deregistered with URLProtocol, and how it works internally, it must be stored and used as a global context.
///
/// - parameter context: The global context to be set. You can reset (and disable) mocking by specifying `nil` here.
public func setGlobalContext(_ context: MockingContext?) {
    ctx = context
}

public final class MockingContext {
    public typealias RequestFilter = (URLRequest) -> (Bool)

    private var responseForURL : [URL: URLResponse] = [:]
    private var responseForRequestFilter: [(matcher: RequestFilter, response: URLResponse)] = []
    private var mockedRequests : [URLRequest] = []
    private let mutex: Mutex

    private let configuration: URLSessionConfiguration?

    public init(configuration: URLSessionConfiguration?) {
        mutex = Mutex(recursive: true)

        URLProtocol.registerClass(MockURLProtocol.self)

        self.configuration = configuration

        if var protoClasses = configuration?.protocolClasses {
            protoClasses = [MockURLProtocol.self as AnyClass] + protoClasses
            configuration?.protocolClasses = protoClasses
        }
    }

    deinit {
        URLProtocol.unregisterClass(MockURLProtocol.self)

        if let configuration = configuration, var protocols = configuration.protocolClasses {

            let foundIndex = protocols.index { $0 == MockURLProtocol.self }
            if let indexToRemove = foundIndex {
                protocols.remove(at: indexToRemove)
            }

            configuration.protocolClasses = protocols
        }

    }

    private func withLock<U>( _ f: @noescape (MockingContext) -> U) -> U {
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

    public func add(_ request: URLRequest) {
        withLock { $0.mockedRequests.append(request) }
    }

    public func remove(_ request: URLRequest) {
        withLock {
            if let findIndex = $0.mockedRequests.index(of: request) {
                $0.mockedRequests.remove(at: findIndex)
            }
        }
    }

    public func register(_ response: URLResponse, for url: URL) {
        withLock { $0.responseForURL[url] = response }
    }

    public func register(_ response: URLResponse, for requestFilter: RequestFilter) {
        withLock { $0.responseForRequestFilter.append((matcher: requestFilter, response: response)) }
    }

    public func response(for url: URL) -> URLResponse? {
        return withLock { $0.responseForURL[url] ?? $0.defaultResponse }
    }

    public func response(for request: URLRequest) -> URLResponse? {
        return withLock {
            for obj in $0.responseForRequestFilter {
                if (obj.matcher(request)) {
                    return obj.response
                }
            }
            if let url = request.url {
                return $0.response(for: url)
            }

            return nil
        }
    }
}
