import Quick
import Nimble
import MockHTTP

class MockHTTPSpec: QuickSpec {
    override func spec() {
        let url = NSURL(string: "http://example.com/foo")!
        var configuration: NSURLSessionConfiguration! = nil
        var mockingContext: MockHTTP.MockingContext!

        beforeEach {
            configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            mockingContext = MockingContext(configuration: configuration)
            MockHTTP.setGlobalContext(mockingContext)
        }

        describe("mocking http requests by URL") {
            let data = NSString(string: "hello").dataUsingEncoding(NSUTF8StringEncoding)!
            let headers = ["foo": "bar"]
            let response = MockHTTP.URLResponse(statusCode: 200, headers: headers, body: data)

            var session : NSURLSession!
            var request : NSURLRequest!
            var httpResponse : NSHTTPURLResponse?

            beforeEach {
                mockingContext.registerResponse(response, forURL: url)
                request = NSURLRequest(URL: url)
                session = NSURLSession(configuration: configuration)
            }

            it("should return the registered response") {
                waitUntil(timeout: 1) { done in
                    session.dataTaskWithRequest(request, completionHandler: { (body, urlResponse, error) -> Void in
                        httpResponse = urlResponse as? NSHTTPURLResponse
                        expect(body).to(equal(data))
                        expect(httpResponse?.statusCode).to(equal(200))
                        expect(mockingContext.requests().count).to(equal(1))
                        expect(mockingContext.requests().last?.URL?.absoluteString).to(equal("http://example.com/foo"))
                        done()
                    }).resume()
                }
            }
        }

        describe("mocking http requests for request filter") {
            let data = NSString(string: "hello").dataUsingEncoding(NSUTF8StringEncoding)!
            let headers = ["foo": "bar"]
            let response = MockHTTP.URLResponse(statusCode: 200, headers: headers, body: data)

            var session : NSURLSession! = nil
            var request : NSMutableURLRequest! = nil
            var httpResponse : NSHTTPURLResponse? = nil

            beforeEach {
                mockingContext.registerResponse(response) {(request: NSURLRequest) -> Bool in
                    return request.HTTPMethod == "PUT"
                }

                request = NSMutableURLRequest(URL: url)
                request.HTTPMethod = "PUT"

                session = NSURLSession(configuration: configuration)
            }

            it("should return the registered response") {
                waitUntil(timeout: 1) { done in
                    session.dataTaskWithRequest(request, completionHandler: { (body, urlResponse, error) -> Void in
                        httpResponse = urlResponse as? NSHTTPURLResponse
                        expect(body).to(equal(data))
                        expect(httpResponse?.statusCode).to(equal(200))
                        expect(mockingContext.requests().count).to(equal(1))
                        expect(mockingContext.requests().last?.URL?.absoluteString).to(equal("http://example.com/foo"))
                        done()
                    }).resume()
                }
            }
        }

        describe("making a request that is not registered") {
            context("with a default response") {
                beforeEach {
                    let response = MockHTTP.URLResponse(statusCode: 404, headers: [:], body: nil)
                    mockingContext.defaultResponse = response
                }

                it("should return the default response") {
                    let request = NSURLRequest(URL: url)
                    let session = NSURLSession(configuration: configuration)

                    waitUntil(timeout: 1) { done in
                        session.dataTaskWithRequest(request, completionHandler: { (body, urlResponse, error) in
                            let httpResponse = urlResponse as? NSHTTPURLResponse
                            expect(httpResponse?.statusCode).to(equal(404))
                            done()
                        }).resume()
                    }
                }
            }

            context("without a default response") {
                it("should fail") {
                    let request = NSURLRequest(URL: url)
                    let session = NSURLSession(configuration: configuration)

                    waitUntil(timeout: 1) { done in
                        session.dataTaskWithRequest(request, completionHandler: { (body, urlResponse, error) in
                            expect(error).toNot(beNil())
                            done()
                        }).resume()
                    }
                }
            }
        }
    }
}
