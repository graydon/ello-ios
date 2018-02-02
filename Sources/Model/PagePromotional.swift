////
///  PagePromotional.swift
//

import SwiftyJSON


@objc(PagePromotional)
final class PagePromotional: JSONAble {
    // version 1: initial
    // version 2: isEditorial / isArtistInvite
    static let Version = 2

    let id: String
    let postToken: String?
    let header: String
    let subheader: String
    let ctaCaption: String
    let ctaURL: URL?
    let image: Asset?
    var tileURL: URL? { return image?.oneColumnAttachment?.url }
    var isCategory: Bool { return !isEditorial && !isArtistInvite }
    var isEditorial: Bool
    var isArtistInvite: Bool

    var user: User? { return getLinkObject("user") as? User }

    init(
        id: String,
        postToken: String?,
        header: String,
        subheader: String,
        ctaCaption: String,
        ctaURL: URL?,
        image: Asset?,
        isEditorial: Bool,
        isArtistInvite: Bool
    ) {
        self.id = id
        self.postToken = postToken
        self.header = header
        self.subheader = subheader
        self.ctaCaption = ctaCaption
        self.ctaURL = ctaURL
        self.image = image
        self.isEditorial = isEditorial
        self.isArtistInvite = isArtistInvite
        super.init(version: PagePromotional.Version)
    }

    required init(coder: NSCoder) {
        let decoder = Coder(coder)
        id = decoder.decodeKey("id")
        postToken = decoder.decodeOptionalKey("postToken")
        header = decoder.decodeKey("header")
        subheader = decoder.decodeKey("subheader")
        ctaCaption = decoder.decodeKey("ctaCaption")
        ctaURL = decoder.decodeOptionalKey("ctaURL")
        image = decoder.decodeOptionalKey("image")
        let version: Int = decoder.decodeKey("version")
        if version > 1 {
            isEditorial = decoder.decodeKey("isEditorial")
            isArtistInvite = decoder.decodeKey("isArtistInvite")
        }
        else {
            isEditorial = false
            isArtistInvite = false
        }
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        let encoder = Coder(coder)
        encoder.encodeObject(id, forKey: "id")
        encoder.encodeObject(postToken, forKey: "postToken")
        encoder.encodeObject(header, forKey: "header")
        encoder.encodeObject(subheader, forKey: "subheader")
        encoder.encodeObject(ctaCaption, forKey: "ctaCaption")
        encoder.encodeObject(ctaURL, forKey: "ctaURL")
        encoder.encodeObject(image, forKey: "image")
        encoder.encodeObject(isEditorial, forKey: "isEditorial")
        encoder.encodeObject(isArtistInvite, forKey: "isArtistInvite")
        super.encode(with: coder)
    }

    class func fromJSON(_ data: [String: Any]) -> PagePromotional {
        let json = JSON(data)
        let id = json["id"].stringValue
        let header = json["header"].stringValue
        let subheader = json["subheader"].stringValue
        let ctaCaption = json["cta_caption"].stringValue
        let ctaURL = json["cta_href"].string.flatMap { URL(string: $0) }
        let postToken = json["post_token"].string

        let image = Asset.parseAsset(id, node: data["image"] as? [String: Any])
        let isEditorial = json["is_editorial"].boolValue
        let isArtistInvite = json["is_artist_invite"].boolValue

        let promotional = PagePromotional(
            id: id,
            postToken: postToken,
            header: header,
            subheader: subheader,
            ctaCaption: ctaCaption,
            ctaURL: ctaURL,
            image: image,
            isEditorial: isEditorial,
            isArtistInvite: isArtistInvite
            )
        promotional.links = data["links"] as? [String: Any]
        return promotional
    }
}

extension PagePromotional: JSONSaveable {
    var uniqueId: String? { return "PagePromotional-\(id)" }
    var tableId: String? { return id }

}
