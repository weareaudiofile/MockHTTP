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
public func setGlobalContext(context: MockingContext?) {
    ctx = context
}

public final class MockingContext {
    private var responseForURL : [NSURL: URLResponse] = [:]
    private var responseForRequestFilter: [(matcher: (NSURLRequest) -> (Bool), response: URLResponse)] = []
    private var mockedRequests : [NSURLRequest] = []
    private let mutex: Mutex

    private let configuration: NSURLSessionConfiguration?

    public init(configuration: NSURLSessionConfiguration?) {
        mutex = Mutex(recursive: true)

        NSURLProtocol.registerClass(URLProtocol.self)

        self.configuration = configuration

        if var protoClasses = configuration?.protocolClasses {
            protoClasses = [URLProtocol.self as AnyClass] + protoClasses
            configuration?.protocolClasses = protoClasses
        }
    }

    deinit {
        NSURLProtocol.unregisterClass(URLProtocol.self)

        if let configuration = configuration, var protocols = configuration.protocolClasses {

            let foundIndex = protocols.indexOf { $0 == URLProtocol.self }
            if let indexToRemove = foundIndex {
                protocols.removeAtIndex(indexToRemove)
            }

            configuration.protocolClasses = protocols
        }

    }

    private func withLock<U>(@noescape f: MockingContext -> U) -> U {
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

    public func requests() -> [NSURLRequest] {
        return withLock { $0.mockedRequests }
    }

    public func addRequest(request: NSURLRequest) {
        withLock { $0.mockedRequests.append(request) }
    }

    public func removeRequest(request: NSURLRequest) {
        withLock {
            if let findIndex = $0.mockedRequests.indexOf(request) {
                $0.mockedRequests.removeAtIndex(findIndex)
            }
        }
    }

    public func registerResponse(response: URLResponse, forURL url: NSURL) {
        withLock { $0.responseForURL[url] = response }
    }

    public func registerResponse(response: URLResponse, forRequestFilter requestFilter: (NSURLRequest) -> (Bool)) {
        withLock { $0.responseForRequestFilter.append((matcher: requestFilter, response: response)) }
    }

    public func responseForURL(url: NSURL) -> URLResponse? {
        return withLock { $0.responseForURL[url] ?? $0.defaultResponse }
    }

    public func responseForRequest(request: NSURLRequest) -> URLResponse? {
        return withLock {
            for obj in $0.responseForRequestFilter {
                if (obj.matcher(request)) {
                    return obj.response
                }
            }
            if let url = request.URL {
                return $0.responseForURL(url)
            }

            return nil
        }
    }
}
