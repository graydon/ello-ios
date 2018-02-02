////
///  Promotional.swift
//

import SwiftyJSON

@objc(Promotional)
final class Promotional: JSONAble {
    // version 1: initial
    static let Version = 1

    let id: String
    let userId: String
    let postToken: String?
    let categoryId: String
    var image: Asset?

    var user: User? { return getLinkObject("user") as? User }

    init(
        id: String,
        userId: String,
        postToken: String?,
        categoryId: String
    ) {
        self.id = id
        self.userId = userId
        self.postToken = postToken
        self.categoryId = categoryId
        super.init(version: Promotional.Version)
    }

    required init(coder: NSCoder) {
        let decoder = Coder(coder)
        id = decoder.decodeKey("id")
        userId = decoder.decodeKey("userId")
        postToken = decoder.decodeOptionalKey("postToken")
        categoryId = decoder.decodeKey("categoryId")
        image = decoder.decodeOptionalKey("image")
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        let encoder = Coder(coder)
        encoder.encodeObject(id, forKey: "id")
        encoder.encodeObject(userId, forKey: "userId")
        encoder.encodeObject(postToken, forKey: "postToken")
        encoder.encodeObject(categoryId, forKey: "categoryId")
        encoder.encodeObject(image, forKey: "image")
        super.encode(with: coder)
    }

    class func fromJSON(_ data: [String: Any]) -> Promotional {
        let json = JSON(data)
        let id = json["id"].stringValue
        let userId = json["user_id"].stringValue
        let postToken = json["post_token"].string
        let categoryId = json["category_id"].stringValue

        let image = Asset.parseAsset(id, node: data["image"] as? [String: Any])

        let promotional = Promotional(
            id: id,
            userId: userId,
            postToken: postToken,
            categoryId: categoryId
            )
        promotional.image = image

        promotional.links = data["links"] as? [String: Any]

        return promotional
    }
}

extension Promotional: JSONSaveable {
    var uniqueId: String? { return "Promotional-\(id)" }
    var tableId: String? { return id }

}
