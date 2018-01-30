////
///  ElloProviderSpec.swift
//

@testable import Ello
import Quick
import Moya
import Nimble
import Alamofire


class TestObserver {
    var handled = false
    var object: Any?

    func handleNotification(_ note: NSNotification) {
        handled = true
        object = note.object
    }
}


class ElloProviderSpec: QuickSpec {
    override func spec() {
        afterEach {
            Globals.isSimulator = true
        }

        describe("ElloProvider") {
            describe("SSL Pinning") {
                it("has a custom Alamofire.Manager") {
                    let defaultManager = SessionManager.default
                    let elloManager = ElloProvider.moya.manager

                    expect(elloManager).notTo(beIdenticalTo(defaultManager))
                }
            }

            describe("logout") {
                it("should reset the AuthToken") {
                    AuthenticationManager.shared.logout()
                    let token = AuthToken()
                    expect(token.isPasswordBased) == false
                }
            }
        }
    }
}
