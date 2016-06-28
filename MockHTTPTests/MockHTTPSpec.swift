import Quick
import Nimble
import MockHTTP

class MockHTTPSpec: QuickSpec {
    override func spec() {
        let url = URL(string: "http://example.com/foo")!
        var configuration: URLSessionConfiguration! = nil
        var mockingContext: MockHTTP.MockingContext!

        beforeEach {
            configuration = URLSessionConfiguration.default()
            mockingContext = MockingContext(configuration: configuration)
            MockHTTP.setGlobalContext(mockingContext)
        }

        describe("mocking http requests by URL") {
            let data = NSString(string: "hello").data(using: String.Encoding.utf8.rawValue)
            let headers = ["foo": "bar"]
            let response = MockHTTP.URLResponse(statusCode: 200, headers: headers, body: data)

            var session : URLSession!
            var request : URLRequest!
            var httpResponse : HTTPURLResponse?

            beforeEach {
                mockingContext.register(response: response, for: url)
                request = URLRequest(url: url)
                session = URLSession(configuration: configuration)
            }

            it("should return the registered response") {
                waitUntil(timeout: 1) { done in
                    session.dataTask(with: request as URLRequest, completionHandler: { (body, urlResponse, error) -> Void in
                        httpResponse = urlResponse as? HTTPURLResponse
                        expect(body).to(equal(data))
                        expect(httpResponse?.statusCode).to(equal(200))
                        expect(mockingContext.requests().count).to(equal(1))
                        expect(mockingContext.requests().last?.url?.absoluteString).to(equal("http://example.com/foo"))
                        done()
                    }).resume()
                }
            }
        }

        describe("mocking http requests for request filter") {
            let data = NSString(string: "hello").data(using: String.Encoding.utf8.rawValue)!
            let headers = ["foo": "bar"]
            let response = MockHTTP.URLResponse(statusCode: 200, headers: headers, body: data)

            var session : URLSession! = nil
            var request : URLRequest! = nil
            var httpResponse : HTTPURLResponse? = nil

            beforeEach {
                mockingContext.register(response: response) {(request: URLRequest) -> Bool in
                    return request.httpMethod == "PUT"
                }

                request = URLRequest(url: url)
                request.httpMethod = "PUT"

                session = URLSession(configuration: configuration)
            }

            it("should return the registered response") {
                waitUntil(timeout: 1) { done in
                    session.dataTask(with: request as URLRequest, completionHandler: { (body, urlResponse, error) -> Void in
                        httpResponse = urlResponse as? HTTPURLResponse
                        expect(body).to(equal(data))
                        expect(httpResponse?.statusCode).to(equal(200))
                        expect(mockingContext.requests().count).to(equal(1))
                        expect(mockingContext.requests().last?.url?.absoluteString).to(equal("http://example.com/foo"))
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
                    let request = URLRequest(url: url)
                    let session = URLSession(configuration: configuration)

                    waitUntil(timeout: 1) { done in
                        session.dataTask(with: request as URLRequest, completionHandler: { (body, urlResponse, error) in
                            let httpResponse = urlResponse as? HTTPURLResponse
                            expect(httpResponse?.statusCode).to(equal(404))
                            done()
                        }).resume()
                    }
                }
            }

            context("without a default response") {
                it("should fail") {
                    let request = NSURLRequest(url: url)
                    let session = URLSession(configuration: configuration)

                    waitUntil(timeout: 1) { done in
                        session.dataTask(with: request as URLRequest, completionHandler: { (body, urlResponse, error) in
                            expect(error).toNot(beNil())
                            done()
                        }).resume()
                    }
                }
            }
        }
    }
}
