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
    public let headers : [String: String]
    public let body : Data?
    public let error : NSError?

    public init(statusCode: Int, headers: [String:String], body: Data?, error: NSError? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.error = error
    }

    public convenience init(string: String, statusCode: Int, headers: [String: String] = [:]) {
        let body = NSString(string: string).data(using: String.Encoding.utf8.rawValue)
        self.init(statusCode: statusCode, headers: headers, body: body, error: nil)
    }

    public convenience init(json: AnyObject, statusCode: Int, headers: [String: String] = [:]) {
        let body = try? JSONSerialization.data(withJSONObject: json, options: [])
        self.init(statusCode: statusCode, headers: headers, body: body, error: nil)
    }

    public convenience init(error: NSError, statusCode: Int, headers: [String: String] = [:]) {
        self.init(statusCode: statusCode, headers: headers, body: nil, error: error)
    }
}
