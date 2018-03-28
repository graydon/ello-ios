////
///  DiscoverType.swift
//

enum DiscoverType: String {
    case featured = "recommended"
    case trending = "trending"
    case recent = "recent"
    case shop = "shop"

    var slug: String { return rawValue }
    var graphQL: String {
        switch self {
        case .featured: return "FEATURED"
        case .trending: return "TRENDING"
        case .recent: return "RECENT"
        case .shop: return "SHOP"
        }
    }
    var name: String {
        switch self {
        case .featured: return InterfaceString.Discover.Featured
        case .trending: return InterfaceString.Discover.Trending
        case .recent: return InterfaceString.Discover.Recent
        case .shop: return InterfaceString.Discover.Shop
        }
    }
}
