////
///  AuthenticationManager.swift
//

protocol AuthenticationEndpoint {
    var requiresAnyToken: Bool { get }
    var supportsAnonymousToken: Bool { get }
}

class AuthenticationManager {
    typealias RequestAttempt = (AuthenticationEndpoint, Block, Block)

    static var shared = AuthenticationManager()

    private var waitList: [RequestAttempt] = []
    private var authState: AuthState = .initial {
        willSet {
            if newValue != authState && !authState.canTransitionTo(newValue) && !Globals.isTesting {
                print("invalid transition from \(authState) to \(newValue)")
            }
        }
    }

    var isUndetermined: Bool { return authState.isUndetermined }
    var isTransitioning: Bool { return authState.isTransitioning }

    func attemptRequest(_ target: AuthenticationEndpoint, retry: @escaping Block, proceed: (UUID) -> Void, cancel: @escaping Block) {
        let uuid = AuthState.uuid

        if authState.isUndetermined {
            attemptAuthentication(uuid: uuid, request: (target, retry, cancel))
        }
        else if authState.isTransitioning {
            appendRequest((target, retry, cancel))
        }
        else {
            if canMakeRequest(target) {
                proceed(uuid)
            }
            else {
                cancel()
            }
        }
    }

    func canMakeRequest(_ target: AuthenticationEndpoint) -> Bool {
        if !target.requiresAnyToken {
            return true
        }

        if authState.isTransitioning {
            return false
        }

        if authState.isAuthenticated {
            return true
        }

        return target.supportsAnonymousToken && authState == .anonymous
    }

    func logout() {
        if authState.canTransitionTo(.noToken) {
            self.advanceAuthState(.noToken)
        }
    }

    func authenticated(isPasswordBased: Bool) {
        if isPasswordBased {
            self.advanceAuthState(.authenticated)
        }
        else {
            self.advanceAuthState(.anonymous)
        }
    }

    func appendRequest(_ request: RequestAttempt) {
        waitList.append(request)
    }

    // set queue to nil in specs, and reauth requests are sent synchronously.
    var queue: DispatchQueue? = DispatchQueue(label: "com.ello.ReauthQueue", attributes: [])

    func attemptAuthentication(uuid: UUID, request: RequestAttempt? = nil) {
        attemptAuthenticationQueue {
            let shouldResendRequest = uuid != AuthState.uuid
            if let (_, request, _) = request, shouldResendRequest {
                request()
                return
            }

            if let request = request {
                self.waitList.append(request)
            }

            switch self.authState {
            case .initial:
                let authToken = AuthToken()
                if authToken.isPasswordBased {
                    self.authState = .authenticated
                }
                else if authToken.isAnonymous {
                    self.authState = .anonymous
                }
                else {
                    self.authState = .shouldTryAnonymousCreds
                }
                self.advanceAuthState(self.authState)
            case .anonymous:
                // an anonymous-authenticated request resulted in a 401 - we
                // should log the user out
                self.advanceAuthState(.noToken)
            case .authenticated, .shouldTryRefreshToken:
                self.authState = .refreshTokenSent

                let authService = ReAuthService()
                authService.reAuthenticateToken(success: {
                    self.advanceAuthState(.authenticated)
                },
                failure: { _ in
                    self.advanceAuthState(.shouldTryUserCreds)
                }, noNetwork: {
                    self.advanceAuthState(.shouldTryRefreshToken)
                })
            case .shouldTryUserCreds:
                self.authState = .userCredsSent

                let authService = ReAuthService()
                authService.reAuthenticateUserCreds(success: {
                    self.advanceAuthState(.authenticated)
                },
                failure: { _ in
                    self.advanceAuthState(.noToken)
                }, noNetwork: {
                    self.advanceAuthState(.shouldTryUserCreds)
                })
            case .shouldTryAnonymousCreds, .noToken:
                self.authState = .anonymousCredsSent

                let authService = AnonymousAuthService()
                authService.authenticateAnonymously(success: {
                    self.advanceAuthState(.anonymous)
                }, failure: { _ in
                    self.advanceAuthState(.noToken)
                }, noNetwork: {
                    self.advanceAuthState(.shouldTryAnonymousCreds)
                })
            case .refreshTokenSent, .userCredsSent, .anonymousCredsSent:
                break
            }
        }
    }

    private func attemptAuthenticationQueue(_ closure: @escaping () -> Void) {
        if let queue = queue {
            queue.async(execute: closure)
        }
        else {
            closure()
        }
    }

    private func advanceAuthState(_ nextState: AuthState) {
        let closure = {
            self.authState = nextState

            if nextState == .noToken {
                AuthState.uuid = UUID()
                AuthToken.reset()

                self.flushWaitList()
                nextTick {
                    self.postInvalidTokenNotification()
                }
            }
            else if nextState == .anonymous {
                // if you were using the app, but got logged out, you will
                // quickly receive an anonymous token.  If any Requests don't
                // support this flow , we should kick you out and present the
                // log in screen.  During login/join, though, all the Requests
                // *will* support an anonymous token.
                //
                // if, down the road, we have anonymous browsing, we should
                // require and implement robust invalidToken handlers for all
                // Controllers & Services

                AuthState.uuid = UUID()

                self.flushWaitList()
            }
            else if nextState.isAuthenticated {
                AuthState.uuid = UUID()
                self.flushWaitList()
            }
            else {
                sleep(1)
                self.attemptAuthentication(uuid: AuthState.uuid)
            }
        }

        if let queue = queue {
            queue.async(execute: closure)
        }
        else {
            closure()
        }
    }

    private func flushWaitList() {
        let currentWaitList = waitList
        waitList = []

        let runWaitList = {
            for (target, makeRequest, cancelRequest) in currentWaitList {
                if self.canMakeRequest(target) {
                    makeRequest()
                }
                else {
                    cancelRequest()
                }
            }
        }

        if queue == nil {
            runWaitList()
        }
        else {
            DispatchQueue.main.async(execute: runWaitList)
        }
    }

    private func postInvalidTokenNotification() {
        postNotification(AuthenticationNotifications.invalidToken, value: ())
    }
}

extension AuthenticationManager {
    func specs(setAuthState authState: AuthState) {
        self.authState = authState
    }
}
