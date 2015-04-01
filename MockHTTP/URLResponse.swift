//
//  URLResponse.swift
//  MockHTTP
//
//  Created by Rachel Brindle on 3/31/15.
//  Copyright (c) 2015 Rachel Brindle. All rights reserved.
//

import Foundation

public class URLResponse {
    public let statusCode : Int
    public let headers : [NSObject: AnyObject]
    public let body : NSData?
    public let error : NSError?

    public init(statusCode: Int, headers: [NSObject: AnyObject], body: NSData?, error: NSError? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.error = error
    }
}