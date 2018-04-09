////
///  AnonymousAuthenticationSpec.swift
//

@testable import Ello
import Quick
import Nimble


class AnonymousAuthenticationSpec: QuickSpec {
    override func spec() {
        describe("AnonymousAuthentication") {
            beforeEach {
                AuthToken.reset()
            }

            it("should request anonymous credentials when no credentials are available") {
                AuthenticationManager.shared.specs(setAuthState: .noToken)

                var succeeded = false
                var failed = false
                ElloProvider.shared.request(.availability(content: [:]))
                    .done { _ in
                        succeeded = true
                    }
                    .catch { _ in
                        failed = true
                    }
                expect(AuthToken().token) == "0237a2b08dfe6c30bd3c1525767efadffac942bbb6c045c924ff2eba1350c4aa"
                expect(AuthToken().isPasswordBased) == false
                expect(succeeded) == true
                expect(failed) == false
            }

            it("should request anonymous credentials initially when no credentials are available") {
                AuthenticationManager.shared.specs(setAuthState: .initial)

                var succeeded = false
                var failed = false
                ElloProvider.shared.request(.availability(content: [:]))
                    .done { _ in
                        succeeded = true
                    }
                    .catch { _ in
                        failed = true
                    }
                expect(AuthToken().token) == "0237a2b08dfe6c30bd3c1525767efadffac942bbb6c045c924ff2eba1350c4aa"
                expect(AuthToken().isPasswordBased) == false
                expect(succeeded) == true
                expect(failed) == false
            }

            it("should fail requests that need authentication when anonymous credentials are available") {
                AuthenticationManager.shared.specs(setAuthState: .anonymous)

                var succeeded = false
                var failed = false
                ElloProvider.shared.request(.following)
                    .done { _ in
                        succeeded = true
                    }
                    .catch { _ in
                        failed = true
                    }
                expect(succeeded) == false
                expect(failed) == true
            }

            it("should fail anonymous requests when anonymous credentials are invalid") {
                ElloProvider.moya = ElloProvider.RecordedStubbingProvider([
                    RecordedResponse(endpoint: .availability(content: [:]), response: .networkResponse(401, Data())),
                ])
                AuthenticationManager.shared.specs(setAuthState: .anonymous)

                var succeeded = false
                var failed = false
                ElloProvider.shared.request(.availability(content: [:]))
                    .done { _ in
                        succeeded = true
                    }
                    .catch { _ in
                        failed = true
                    }
                expect(succeeded) == false
                expect(failed) == true
            }
        }
    }
}
