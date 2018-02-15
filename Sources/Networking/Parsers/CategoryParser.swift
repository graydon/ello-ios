////
///  CategoryParser.swift
//

import SwiftyJSON


class CategoryParser: IdParser {

    init() {
        super.init(table: .categoriesType)
    }

    override func parse(json: JSON) -> Category {
        let level: CategoryLevel = CategoryLevel(rawValue: json["level"].stringValue) ?? .unknown
        let tileImage: Attachment?
        if let attachmentJson = json["tileImage"]["large"].object as? [String: Any] {
            tileImage = Attachment.fromJSON(attachmentJson)
        }
        else {
            tileImage = nil
        }

        let category = Category(
            id: json["id"].stringValue,
            name: json["name"].stringValue,
            slug: json["slug"].stringValue,
            order: json["order"].intValue,
            allowInOnboarding: json["allowInOnboarding"].bool ?? true,
            isCreatorType: json["isCreatorType"].bool ?? true,
            level: level,
            tileImage: tileImage
        )

        category.links = json["links"].dictionaryObject

        return category
    }
}
