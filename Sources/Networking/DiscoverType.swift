////
///  DiscoverType.swift
//

enum DiscoverType: String {
    case featured = "recommended"
    case trending = "trending"
    case recent = "recent"

    var slug: String { return rawValue }
    var name: String {
        switch self {
        case .featured: return InterfaceString.Discover.Featured
        case .trending: return InterfaceString.Discover.Trending
        case .recent: return InterfaceString.Discover.Recent
        }
    }
}
