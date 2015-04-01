//
//  MockHTTP.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

private var responseForURL : [NSURL: URLResponse] = [:]
private var mockedRequests : [NSURLRequest] = []

public func startMocking(configuration: NSURLSessionConfiguration?) {
    responseForURL = [:]
    mockedRequests = []
    NSURLProtocol.registerClass(URLProtocol.self)
    if let configuration = configuration {
        configuration.protocolClasses = [URLProtocol.self] + configuration.protocolClasses!
    }
}

public func stopMocking(configuration: NSURLSessionConfiguration?) {
    NSURLProtocol.unregisterClass(URLProtocol.self)
    if let configuration = configuration, protocols = configuration.protocolClasses {
        let protocolClasses = NSMutableArray(array: protocols)
        protocolClasses.removeObject(URLProtocol.self)
        configuration.protocolClasses = protocolClasses as [AnyObject]
    }
}

public func requests() -> [NSURLRequest] {
    return mockedRequests
}

public func addRequest(request: NSURLRequest) {
    mockedRequests.append(request)
}

public func registerURL(url: NSURL, withResponse response: URLResponse) {
    responseForURL[url] = response
}

public func responseForURL(url: NSURL) -> URLResponse? {
    return responseForURL[url]
}

public func reset() {
    responseForURL = [:]
    mockedRequests = []
}