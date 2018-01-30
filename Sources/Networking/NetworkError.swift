////
///  NetworkError.swift
//

let ElloErrorDomain = "co.ello.Ello"

enum ElloErrorCode: Int {
    case imageMapping = 0
    case jsonMapping
    case stringMapping
    case statusCode
    case data
    case networkFailure
}

extension NSError {

    class func networkError(_ error: Any?, code: ElloErrorCode) -> NSError {
        var userInfo: [String: Any]?
        if let error: Any = error {
            userInfo = [NSLocalizedFailureReasonErrorKey: error]
        }
        else {
            userInfo = [NSLocalizedFailureReasonErrorKey: "\(code)"]
        }
        return NSError(domain: ElloErrorDomain, code: code.rawValue, userInfo: userInfo)
    }

}
