////
///  CategoryLevel.swift
//

enum CategoryLevel: String {
    case meta = "meta"
    case promoted = "promoted"
    case primary = "primary"
    case secondary = "secondary"
    case tertiary = "tertiary"
    case unknown = ""

    var order: Int {
        switch self {
        case .meta: return 0
        case .promoted: return 1
        case .primary: return 2
        case .secondary: return 3
        case .tertiary: return 4
        case .unknown: return 1_048_576
        }
    }
}
