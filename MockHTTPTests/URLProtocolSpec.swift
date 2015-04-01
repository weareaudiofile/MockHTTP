import Quick
import Nimble
import MockHTTP

class URLProtocolSpec: QuickSpec {
    override func spec() {
        var request : NSURLRequest! = nil

        describe("with an http request") {
            beforeEach {
                request = NSURLRequest(URL: NSURL(string: "http://example.com")!)
            }

            it("can init request") {
                expect(MockHTTP.URLProtocol.canInitWithRequest(request)).to(beTruthy())
            }
        }

        describe("with a non-http request") {
            beforeEach {
                request = NSURLRequest(URL: NSURL(string: "ftp://example.com")!)
            }

            it("can't init request") {
                expect(MockHTTP.URLProtocol.canInitWithRequest(request)).to(beFalsy())
            }
        }
    }
}
