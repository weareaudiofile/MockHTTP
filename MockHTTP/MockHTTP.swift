//
//  MockHTTP.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

private var responseForURL : [NSURL: URLResponse] = [:]
private var responseForRequestFilter: [(matcher: (NSURLRequest) -> (Bool), response: URLResponse)] = []
private var mockedRequests : [NSURLRequest] = []
private var defaultResponse: URLResponse? = nil

public func startMocking(configuration: NSURLSessionConfiguration?) {
    responseForURL = [:]
    responseForRequestFilter = []
    mockedRequests = []
    NSURLProtocol.registerClass(URLProtocol.self)
    if let configuration = configuration {
        configuration.protocolClasses = [URLProtocol.self] + configuration.protocolClasses!
    }
}

public func stopMocking(configuration: NSURLSessionConfiguration?) {
    NSURLProtocol.unregisterClass(URLProtocol.self)
    defaultResponse = nil
    if let configuration = configuration, protocols = configuration.protocolClasses {
        let protocolClasses = NSMutableArray(array: protocols)
        protocolClasses.removeObject(URLProtocol.self)
        configuration.protocolClasses = protocolClasses as [AnyObject]
    }
}

// call with nil to remove the default response
public func setDefaultResponse(response: URLResponse?) {
    defaultResponse = response
}

public func requests() -> [NSURLRequest] {
    return mockedRequests
}

public func addRequest(request: NSURLRequest) {
    mockedRequests.append(request)
}

public func registerResponse(response: URLResponse, forURL url: NSURL) {
    responseForURL[url] = response
}

public func registerResponse(response: URLResponse, forRequestFilter requestFilter: (NSURLRequest) -> (Bool)) {
    responseForRequestFilter.append((matcher: requestFilter, response: response))
}

private func responseForURL(url: NSURL) -> URLResponse? {
    return responseForURL[url] ?? defaultResponse
}

public func responseForRequest(request: NSURLRequest) -> URLResponse? {
    for obj in responseForRequestFilter {
        if (obj.matcher(request)) {
            return obj.response
        }
    }
    if let url = request.URL {
        return responseForURL(url)
    }
    return nil;
}

public func reset() {
    responseForURL = [:]
    mockedRequests = []
}