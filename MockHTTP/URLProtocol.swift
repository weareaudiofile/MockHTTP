//
//  URLProtocol.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

public class URLProtocol : NSURLProtocol {
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        let result = request.URL?.scheme == "http"
        return result
    }

    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }

    override public class func requestIsCacheEquivalent(a: NSURLRequest, toRequest:NSURLRequest) -> Bool {
        return false
    }

    override public func startLoading() {
        addRequest(self.request)
        if let url = self.request.URL, let response = responseForRequest(self.request),
           let urlResponse = NSHTTPURLResponse(URL: url, statusCode: response.statusCode, HTTPVersion: "1.1", headerFields: response.headers) {
            self.client?.URLProtocol(self, didReceiveResponse: urlResponse, cacheStoragePolicy: .NotAllowed)
            if let body = response.body {
                self.client?.URLProtocol(self, didLoadData: body)
            }
            if let error = response.error {
                self.client?.URLProtocol(self, didFailWithError: error)
            } else {
                self.client?.URLProtocolDidFinishLoading(self)
            }
        } else {
            let message = "Request for URL: \(self.request.URL) not registered"
            let userInfo : [NSObject: AnyObject] = [NSLocalizedDescriptionKey: message]
            let error = NSError(domain: "MockHTTP", code: 1, userInfo: userInfo)
            self.client?.URLProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {

    }
}
