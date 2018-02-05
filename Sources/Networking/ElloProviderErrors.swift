////
///  ElloProviderErrors.swift
//

extension ElloProvider {

    static func unCastableJSONAble(_ failure: ElloFailureCompletion) {
        let elloError = NSError.uncastableJSONAble()
        failure(elloError, 200)
    }

    static func generateElloError(_ data: Data?, statusCode: Int?) -> NSError {
        var elloNetworkError: ElloNetworkError?
        if let dictJSONDecoded = try? JSONSerialization.jsonObject(with: data),
            let dictJSON = dictJSONDecoded as? [String: Any],
            let node = dictJSON[MappingType.errorsType.rawValue] as? [String: Any]
        {
            elloNetworkError = Mapper.mapToObject(node, type: .errorType) as? ElloNetworkError
        }
        else if let string = String(data: data, encoding: .utf8) {
            print("error: \(string)")
        }

        let errorCodeType = (statusCode == nil) ? ElloErrorCode.data : ElloErrorCode.statusCode
        let elloError = NSError.networkError(elloNetworkError, code: errorCodeType)

        return elloError
    }

    static func failedToSendRequest(_ failure: ElloFailureCompletion) {
        let elloError = NSError.networkError("Failed to send request", code: ElloErrorCode.networkFailure)
        failure(elloError, nil)
    }

    static func failedToMapObjects(_ failure: ElloFailureCompletion) {
        let jsonMappingError = ElloNetworkError(attrs: nil, code: ElloNetworkError.CodeType.unknown, detail: "Failed to map objects", messages: nil, status: nil, title: "Failed to map objects")
        let elloError = NSError.networkError(jsonMappingError, code: ElloErrorCode.jsonMapping)
        failure(elloError, nil)
    }
}
