//
//  MockHTTP.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

private class MockingContext {
    private var responseForURL : [NSURL: URLResponse] = [:]
    private var responseForRequestFilter: [(matcher: (NSURLRequest) -> (Bool), response: URLResponse)] = []
    private var mockedRequests : [NSURLRequest] = []
    private var mutex = pthread_mutex_t()
    private var mutexAttr = pthread_mutexattr_t()

    private init() {
        pthread_mutexattr_init(&mutexAttr)
        pthread_mutexattr_settype(&mutexAttr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &mutexAttr)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    private func withLock<U>(f: MockingContext -> U) -> U {
        pthread_mutex_lock(&mutex)
        let returned = f(self)
        pthread_mutex_unlock(&mutex)

        return returned
    }

    private var defaultResponse: URLResponse?

    func setDefaultResponse(response: URLResponse?) {
        withLock { $0.defaultResponse = response }
    }

    func clearDefaultResponse() {
        withLock { $0.defaultResponse = nil }
    }

    func addRequest(request: NSURLRequest) {
        withLock { $0.mockedRequests.append(request) }
    }

    func removeRequest(request: NSURLRequest) {
        withLock {
            if let findIndex = $0.mockedRequests.indexOf(request) {
                $0.mockedRequests.removeAtIndex(findIndex)
            }
        }
    }

    private func registerResponse(response: URLResponse, forURL url: NSURL) {
        withLock { $0.responseForURL[url] = response }
    }

    private func registerResponse(response: URLResponse, forRequestFilter requestFilter: (NSURLRequest) -> (Bool)) {
        withLock { $0.responseForRequestFilter.append((matcher: requestFilter, response: response)) }
    }

    private func responseForURL(url: NSURL) -> URLResponse? {
        return withLock { $0.responseForURL[url] ?? $0.defaultResponse }
    }

    private func responseForRequest(request: NSURLRequest) -> URLResponse? {
        return withLock {
            for obj in $0.responseForRequestFilter {
                if (obj.matcher(request)) {
                    return obj.response
                }
            }
            if let url = request.URL {
                // TODO: Fix recursion here!
                return $0.responseForURL(url)
            }
            return nil
        }
    }

}

private var ctx = MockingContext()

public func startMocking(configuration: NSURLSessionConfiguration?) {
    ctx = MockingContext()

    NSURLProtocol.registerClass(URLProtocol.self)

    if var protoClasses = configuration?.protocolClasses {
        protoClasses = [URLProtocol.self as AnyClass] + protoClasses
        configuration?.protocolClasses = protoClasses
    }
}

public func stopMocking(configuration: NSURLSessionConfiguration?) {
    NSURLProtocol.unregisterClass(URLProtocol.self)

    ctx.clearDefaultResponse()

    if let configuration = configuration, var protocols = configuration.protocolClasses {

        let foundIndex = protocols.indexOf { $0 == URLProtocol.self }
        if let indexToRemove = foundIndex {
            protocols.removeAtIndex(indexToRemove)
        }

        configuration.protocolClasses = protocols
    }
}

// call with nil to remove the default response
public func setDefaultResponse(response: URLResponse?) {
    ctx.withLock { $0.defaultResponse = response }
}

public func requests() -> [NSURLRequest] {
    return ctx.withLock { $0.mockedRequests }
}

public func addRequest(request: NSURLRequest) {
    ctx.addRequest(request)
}

public func removeRequest(request: NSURLRequest) {
    ctx.removeRequest(request)
}

public func registerResponse(response: URLResponse, forURL url: NSURL) {
    ctx.registerResponse(response, forURL: url)
}

public func registerResponse(response: URLResponse, forRequestFilter requestFilter: (NSURLRequest) -> (Bool)) {
    return ctx.registerResponse(response, forRequestFilter: requestFilter)
}

private func responseForURL(url: NSURL) -> URLResponse? {
    return ctx.responseForURL(url)
}

public func responseForRequest(request: NSURLRequest) -> URLResponse? {
    return ctx.responseForRequest(request)
}

public func reset() {
    ctx = MockingContext()
}