////
///  ElloProvider.swift
//

import Moya
import Result
import Alamofire
import PromiseKit
import WebLinking


typealias ElloSuccessCompletion = (Any, ResponseConfig) -> Void
typealias ElloFailureCompletion = (Swift.Error) -> Void
typealias ElloRequestFuture = (target: ElloAPI, resolve: ElloSuccessCompletion, reject: ElloFailureCompletion)
typealias ElloAPIResponse = (Any, ResponseConfig)


class ElloProvider {
    static var shared: ElloProvider = ElloProvider()
    var authState: AuthState = .initial {
        willSet {
            if newValue != authState && !authState.canTransitionTo(newValue) && !Globals.isTesting {
                print("invalid transition from \(authState) to \(newValue)")
            }
        }
    }

    static func endpointClosure(_ target: ElloAPI) -> Endpoint<ElloAPI> {
        let endpoint = Endpoint<ElloAPI>(url: url(target), sampleResponseClosure: { return target.stubbedNetworkResponse }, method: target.method, parameters: target.parameters, parameterEncoding: target.parameterEncoding)
        return endpoint.adding(newHTTPHeaderFields: target.headers())
    }

    static func DefaultProvider() -> MoyaProvider<ElloAPI> {
        return MoyaProvider<ElloAPI>(endpointClosure: ElloProvider.endpointClosure, manager: ElloManager.manager)
    }

    static func ShareExtensionProvider() -> MoyaProvider<ElloAPI> {
        return MoyaProvider<ElloAPI>(endpointClosure: ElloProvider.endpointClosure, manager: ElloManager.shareExtensionManager)
    }

    private struct SharedProvider {
        static var instance = ElloProvider.DefaultProvider()
    }

    static var oneTimeProvider: MoyaProvider<ElloAPI>?
    static var sharedProvider: MoyaProvider<ElloAPI> {
        get {
            if let provider = oneTimeProvider {
                oneTimeProvider = nil
                return provider
            }
            return SharedProvider.instance
        }

        set {
            SharedProvider.instance = newValue
        }
    }

    // MARK: - Public

    func request(_ target: ElloAPI) -> Promise<ElloAPIResponse> {
        let (promise, resolve, reject) = Promise<ElloAPIResponse>.pending()
        elloRequest((target, resolve: resolve, reject: reject))
        return promise
    }

    private func elloRequest(_ request: ElloRequestFuture) {
        let uuid = AuthState.uuid

        if authState.isUndetermined {
            self.attemptAuthentication(request: request, uuid: uuid)
        }
        else if authState.isTransitioning {
            waitList.append(request)
        }
        else {
            let target = request.target
            let canMakeRequest = authState.supports(target)
            if canMakeRequest {
                ElloProvider.sharedProvider.request(target) { result in
                    self.handleRequest(request: request, result: result, uuid: uuid)
                }
            }
            else {
                requestFailed(request: request)
            }
        }
    }

    private func requestFailed(request: ElloRequestFuture) {
        let elloError = NSError(domain: ElloErrorDomain, code: 401, userInfo: [NSLocalizedFailureReasonErrorKey: "Logged Out"])
        inForeground {
            request.reject(elloError)
        }
    }

    var waitList: [ElloRequestFuture] = []

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

    // set queue to nil in specs, and reauth requests are sent synchronously.
    var queue: DispatchQueue? = DispatchQueue(label: "com.ello.ReauthQueue", attributes: [])
    private func attemptAuthentication(request: ElloRequestFuture? = nil, uuid: UUID) {
        let closure = {
            let shouldResendRequest = uuid != AuthState.uuid
            if let request = request, shouldResendRequest {
                self.elloRequest(request)
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

                for request in self.waitList {
                    if nextState.supports(request.target) {
                        self.elloRequest(request)
                    }
                    else {
                        self.requestFailed(request: request)
                    }
                }
                self.waitList = []
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

                for request in self.waitList {
                    if !nextState.supports(request.target) {
                        self.requestFailed(request: request)
                    }
                    else {
                        self.elloRequest(request)
                    }
                }
                self.waitList = []
            }
            else if nextState.isAuthenticated {
                AuthState.uuid = UUID()

                let flushWaitList: Block = {
                    for request in self.waitList {
                        self.elloRequest(request)
                    }
                    self.waitList = []
                }

                if self.queue == nil {
                    flushWaitList()
                }
                else {
                    DispatchQueue.main.async(execute: flushWaitList)
                }
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

}


// MARK: elloRequest implementation
extension ElloProvider {

    // MARK: - Private

    private func handleRequest(request: ElloRequestFuture, result: MoyaResult, uuid: UUID) {
        switch result {
        case let .success(moyaResponse):
            switch moyaResponse.statusCode {
            case 200...299, 300...399:
                handleNetworkSuccess(request: request, response: moyaResponse)
            case 410:
                postOldAPINotification()
            case 401:
                attemptAuthentication(request: request, uuid: uuid)
            default:
                handleServerError(request: request, response: moyaResponse)
            }
        case .failure:
            handleNetworkFailure(request: request)
        }
    }

    private func handleNetworkSuccess(request: ElloRequestFuture, response moyaResponse: Moya.Response) {
        let response = moyaResponse.response as? HTTPURLResponse
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode

        let mappedJSON = try? JSONSerialization.jsonObject(with: data)
        let responseConfig = parseResponse(response)
        if let dict = mappedJSON as? [String: Any] {
            parseLinked(request: request, dict: dict, responseConfig: responseConfig)
        }
        else if isEmptySuccess(data, statusCode: statusCode) {
            request.resolve("", responseConfig)
        }
        else {
            ElloProvider.failedToMapObjects(request: request)
        }
    }

    private func parseLinked(request: ElloRequestFuture, dict: [String: Any], responseConfig: ResponseConfig) {
        let completion: Block = {
            let elloAPI = request.target
            let node = dict[elloAPI.mappingType.rawValue]
            var newResponseConfig: ResponseConfig?
            if let pagingPath = elloAPI.pagingPath,
                let links = (node as? [String: Any])?["links"] as? [String: Any],
                let pagingPathNode = links[pagingPath] as? [String: Any],
                let pagination = pagingPathNode["pagination"] as? [String: String]
            {
                newResponseConfig = self.parsePagination(pagination)
            }

            guard elloAPI.mappingType != .noContentType else {
                request.resolve(UnknownJSONAble(), newResponseConfig ?? responseConfig)
                return
            }

            let mappedObjects: Any?
            if let node = node as? [[String: Any]] {
                mappedObjects = Mapper.mapToObjectArray(node, type: elloAPI.mappingType)
            }
            else if let node = node as? [String: Any] {
                mappedObjects = Mapper.mapToObject(node, type: elloAPI.mappingType)
            }
            else {
                mappedObjects = nil
            }

            if let mappedObjects = mappedObjects {
                request.resolve(mappedObjects, newResponseConfig ?? responseConfig)
            }
            else {
                ElloProvider.failedToMapObjects(request: request)
            }
        }

        if let linked = dict["linked"] as? [String: [[String: Any]]] {
            ElloLinkedStore.shared.parseLinked(linked, completion: completion)
        }
        else {
            completion()
        }
    }

    private func parsePagination(_ node: [String: String]) -> ResponseConfig {
        let config = ResponseConfig()
        config.totalPages = node["total_pages"]
        config.totalCount = node["total_count"]
        config.totalPagesRemaining = node["total_pages_remaining"]
        if let next = node["next"] {
            if let components = URLComponents(string: next) {
                config.nextQuery = components
            }
        }
        return config
    }

    private func parseResponse(_ response: HTTPURLResponse?) -> ResponseConfig {
        let config = ResponseConfig()

        if let response = response {
            config.statusCode = response.statusCode
            config.lastModified = response.allHeaderFields["Last-Modified"] as? String
            config.totalPages = response.allHeaderFields["X-Total-Pages"] as? String
            config.totalCount = response.allHeaderFields["X-Total-Count"] as? String
            config.totalPagesRemaining = response.allHeaderFields["X-Total-Pages-Remaining"] as? String
            config.nextQuery = response.findLink(relation: "next").flatMap { URLComponents(string: $0.uri) }
        }

        return config
    }

    private func isEmptySuccess(_ data: Data, statusCode: Int?) -> Bool {
        guard let statusCode = statusCode else { return false }

        // accepted || no content
        if statusCode == 202 || statusCode == 204 {
            return true
        }
        // no content
        return String(data: data, encoding: .utf8) == "" &&
                statusCode >= 200 &&
                statusCode < 400
    }

    private func handleServerError(request: ElloRequestFuture, response moyaResponse: Moya.Response) {
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        let elloError = ElloProvider.generateElloError(data, statusCode: statusCode)
        Tracker.shared.encounteredNetworkError(request.target.path, error: elloError, statusCode: statusCode)
        request.reject(elloError)
    }

    private func handleNetworkFailure(request: ElloRequestFuture) {
        delay(1) {
            self.elloRequest(request)
        }
    }

    private func postOldAPINotification() {
        postNotification(AuthenticationNotifications.outOfDateAPI, value: ())
    }

    private func postInvalidTokenNotification() {
        postNotification(AuthenticationNotifications.invalidToken, value: ())
    }

}
