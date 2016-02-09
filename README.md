##MockHTTP - Simple HTTP request mocks

MockHTTP allows you to insert dummy requests into the Foundation URL Loading system.

This is useful for testing how you respond to various network requests, as it allows you to mock out how the network should behave instead of having to set up a server to return exactly what you want.

###Usage

MockHTTP will mock requests made using `NSURLConnection`, `NSURLSession`, and all libraries that build upon them.

It works with Quick, and XCTest. It likely works with other testing frameworks, but is untested.

####NSURLSession

#####Quick

```swift
import Quick
import Nimble
import MockHTTP

class MyExampleSpec: QuickSpec {
    override func spec() {
        var session: NSURLSession!
        var mockingContext: MockingContext!
        var request: NSURLRequest!

        beforeEach {
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            mockingContext = MockingContext(configuration: configuration)

            MockHTTP.setGlobalContext(mockingContext)
            session = NSURLSession(configuration: configuration)
        }

        describe("making a request") {
            var response: MockHTTP.URLResponse! = nil
            beforeEach {
                let url = NSURL(string: "http://example.com/foo")!

                request = NSURLRequest(URL: url)
                response = MockHTTP.URLResponse(string: "hello", statusCode: 200)
                // there's also an encoding for any json serializable object
                mockingContext.registerResponse(response, forURL: url)
            }
            it("is mocked") {
                waitUntil { done in
                    session.dataTaskWithRequest(request) {(body: NSData?, urlResponse: NSURLResponse?, error: NSError?) in
                        let httpResponse = urlResponse as? NSHTTPURLResponse
                        expect(httpResponse?.statusCode).to(equal(200))
                        done()
                    }.resume()
                }
            }
        }
    }
}
```
