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
                    let elloManager = ElloProvider.sharedProvider.manager

                    expect(elloManager).notTo(beIdenticalTo(defaultManager))
                }
            }

            describe("logout") {
                it("should reset the AuthToken") {
                    ElloProvider.shared.logout()
                    let token = AuthToken()
                    expect(token.isPasswordBased) == false
                }
            }

            describe("error responses") {
                describe("with stubbed responses") {
                    describe("a provider") {

                        beforeEach {
                            ElloProvider.sharedProvider = ElloProvider.ErrorStubbingProvider()
                        }

                        context("401") {

                            it("posts a notification with a status of 401") {

                                ElloProvider_Specs.errorStatusCode = .status401

                                var loadedJSONAbles: [JSONAble]?
                                var loadedError: Swift.Error?
                                var object: NSError?
                                var handled = false

                                let testObserver = NotificationObserver(notification: ErrorStatusCode.status401.notification) { error in
                                    object = error
                                    handled = true
                                }

                                let endpoint: ElloAPI = .following
                                ElloProvider.shared.request(endpoint)
                                    .then { response in
                                        loadedJSONAbles = response.0 as? [JSONAble]
                                    }
                                    .catch { error in
                                        loadedError = error
                                    }

                                expect(handled) == true
                                expect(loadedJSONAbles).to(beNil())
                                expect(loadedError).notTo(beNil())
                                expect(object).notTo(beNil())

                                if let elloNetworkError = object?.userInfo[NSLocalizedFailureReasonErrorKey] as? ElloNetworkError {
                                    expect(elloNetworkError.status) == "401"
                                    expect(elloNetworkError.code) == ElloNetworkError.CodeType.unauthenticated
                                    expect(elloNetworkError.detail).to(beNil())
                                }
                                else {
                                    fail("error is not an elloNetworkError")
                                }

                                testObserver.removeObserver()
                            }

                        }

                        context("410") {

                            it("posts a notification with a status of 410") {

                                ElloProvider_Specs.errorStatusCode = .status410

                                var loadedJSONAbles: [JSONAble]?
                                var loadedError: Swift.Error?
                                var handled = false
                                var object: NSError?
                                let testObserver = NotificationObserver(notification: ErrorStatusCode.status410.notification) { error in
                                    handled = true
                                    object = error
                                }

                                ElloProvider.shared.request(.following)
                                    .then { response in
                                        loadedJSONAbles = response.0 as? [JSONAble]
                                    }
                                    .catch { error in
                                        loadedError = error
                                    }

                                expect(handled) == true
                                expect(loadedJSONAbles).to(beNil())
                                expect(loadedError).to(beNil())

                                if let elloNetworkError = object?.userInfo[NSLocalizedFailureReasonErrorKey] as? ElloNetworkError {
                                    expect(elloNetworkError).to(beAnInstanceOf(ElloNetworkError.self))
                                    expect(elloNetworkError.status) == "410"
                                    expect(elloNetworkError.title) == "The requested API version no longer exists."
                                    expect(elloNetworkError.code) == ElloNetworkError.CodeType.invalidVersion
                                    expect(elloNetworkError.detail).to(beNil())
                                }
                                else {
                                    fail("error is not an elloNetworkError")
                                }
                                testObserver.removeObserver()
                            }

                        }
                    }
                }

            }
        }
    }
}
