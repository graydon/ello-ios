////
///  RegionParser.swift
//

import SwiftyJSON

struct RegionParser {

    static func regions(_ key: String, json: JSON, isRepostContent: Bool = false) -> [Regionable] {
        guard let content = json[key].object as? [[String: Any]] else { return [] }

        return content.flatMap { contentDict -> Regionable? in
            guard
                let kindStr = contentDict["kind"] as? String,
                let kind = RegionKind(rawValue: kindStr)
            else { return nil }

            let regionable: Regionable
            switch kind {
            case .text:
                regionable = TextRegion.fromJSON(contentDict)
            case .image:
                regionable = ImageRegion.fromJSON(contentDict)
            case .embed:
                regionable = EmbedRegion.fromJSON(contentDict)
            default:
                return nil
            }

            regionable.isRepost = isRepostContent
            return regionable
        }
    }
}
