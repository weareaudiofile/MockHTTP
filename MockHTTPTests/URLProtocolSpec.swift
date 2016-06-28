import Quick
import Nimble
import MockHTTP

class URLProtocolSpec: QuickSpec {
    override func spec() {
        var request : URLRequest! = nil

        describe("with an http request") {
            beforeEach {
                request = URLRequest(url: URL(string: "http://example.com")!)
            }

            it("can init request") {
                expect(MockHTTP.URLProtocol.canInit(with: request)).to(beTruthy())
            }
        }

        describe("with a non-http request") {
            beforeEach {
                request = URLRequest(url: URL(string: "ftp://example.com")!)
            }

            it("can't init request") {
                expect(MockHTTP.URLProtocol.canInit(with: request)).to(beFalsy())
            }
        }
    }
}
