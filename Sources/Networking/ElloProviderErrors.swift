////
///  ElloProviderErrors.swift
//

extension ElloProvider {

    static func generateElloError(_ data: Data, statusCode: Int?) -> NSError {
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

    static func failedToMapObjects(request: ElloRequestFuture) {
        let jsonMappingError = ElloNetworkError(attrs: nil, code: ElloNetworkError.CodeType.unknown, detail: "Failed to map objects", messages: nil, status: nil, title: "Failed to map objects")
        let elloError = NSError.networkError(jsonMappingError, code: ElloErrorCode.jsonMapping)
        request.reject(elloError)
    }
}
