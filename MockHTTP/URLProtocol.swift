//
//  URLProtocol.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

public class MockURLProtocol : URLProtocol {
    override public class func canInit(with request: URLRequest) -> Bool {
        let result = request.url?.scheme == "http"
        return result
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public class func requestIsCacheEquivalent(_ a: URLRequest, to toRequest:URLRequest) -> Bool {
        return false
    }

    override public func startLoading() {
        ctx?.add(self.request)
        if  let url = self.request.url,
            let response = ctx?.response(for: self.request),
            let urlResponse = HTTPURLResponse(url: url, statusCode: response.statusCode, httpVersion: "1.1", headerFields: response.headers) {
                self.client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
                if let body = response.body {
                    self.client?.urlProtocol(self, didLoad: body)
                }
                if let error = response.error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                } else {
                    self.client?.urlProtocolDidFinishLoading(self)
                }
        } else {
            let message = "Request for URL: \(self.request.url) not registered"
            let userInfo = [NSLocalizedDescriptionKey: message]
            let error = NSError(domain: "MockHTTP", code: 1, userInfo: userInfo)
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {

    }
}
