////
///  StubbedManager.swift
//

@testable import Ello

class StubbedManager: Ello.RequestManager {
    static var current: StubbedManager!

    typealias Stub = (URLRequest) -> StubbedTask?
    var stubs: [Stub] = []

    init() {
        StubbedManager.current = self
    }

    func addStub(_ stub: @escaping Stub) {
        stubs.append(stub)
    }

    func request(_ request: URLRequest, _ handler: @escaping RequestHandler) -> RequestTask {
        var newStubs: [Stub] = []
        var matchingTask: StubbedTask?
        for stub in stubs {
            guard matchingTask == nil, let task = stub(request) else {
                newStubs.append(stub)
                continue
            }

            matchingTask = task
        }
        stubs = newStubs

        return matchingTask ?? StubbedTask(request: request, handler: handler)
    }
}

struct StubbedTask: Ello.RequestTask {
    let request: URLRequest
    let handler: RequestHandler

    func resume() {
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)

        let response = StubbedResponse(
                    request: request,
                    response: httpResponse,
                    data: Data(),
                    error: nil
                )
        self.handler(response)
    }
}

struct StubbedResponse: Ello.Response {
    let request: URLRequest?
    let response: HTTPURLResponse?
    let data: Data?
    let error: Error?
}
