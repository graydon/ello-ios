////
///  NetworkError.swift
//

let ElloErrorDomain = "co.ello.Ello"

enum ElloErrorCode: CustomStringConvertible {
    case imageMapping
    case jsonMapping
    case stringMapping
    case data
    case networkFailure
    case statusCode(Int)

    var intValue: Int {
        switch self {
        case .imageMapping: return 0
        case .jsonMapping: return 1
        case .stringMapping: return 2
        case .data: return 3
        case .networkFailure: return 4
        case let .statusCode(code): return code
        }
    }

    var description: String {
        switch self {
        case .imageMapping: return "imageMapping"
        case .jsonMapping: return "jsonMapping"
        case .stringMapping: return "stringMapping"
        case .data: return "data"
        case .networkFailure: return "networkFailure"
        case let .statusCode(code): return "statusCode(\(code))"
        }
    }

}

extension NSError {

    class func networkError(_ error: Any?, code: ElloErrorCode) -> NSError {
        var userInfo: [String: Any]?
        if let error = error {
            userInfo = [NSLocalizedFailureReasonErrorKey: error]
        }
        else {
            userInfo = [NSLocalizedFailureReasonErrorKey: "\(code)"]
        }
        return NSError(domain: ElloErrorDomain, code: code.intValue, userInfo: userInfo)
    }

}
