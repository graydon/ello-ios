////
///  ElloGraphQL.swift
//

import Alamofire
import PromiseKit
import SwiftyJSON


struct API {
    enum PageHeaderKind {
        case category(String)
        case artistInvites
        case editorials
        case generic

        var apiKind: String {
            switch self {
            case .category: return "CATEGORY"
            case .editorials: return "EDITORIAL"
            case .artistInvites: return "ARTIST_INVITE"
            case .generic: return "GENERIC"
            }
        }

        var slug: String? {
            switch self {
            case let .category(slug): return slug
            default: return nil
            }
        }
    }
    func subscribedCategories() -> GraphQLRequest<[Category]> {
        let request = GraphQLRequest(
            endpointName: "categoryNav",
            parser: ManyParser<Category>(CategoryParser()).parse,
            fragments: """
                fragment imageProps on Image {
                  url
                  metadata { height width type size }
                }

                fragment tshirtImages on TshirtImageVersions {
                  large { ...imageProps }
                }
                """,
            body: """
                id
                name
                slug
                order
                allowInOnboarding
                isCreatorType
                level
                tileImage { ...tshirtImages }
                """
            )
        return request
    }

    func pageHeaders(kind: PageHeaderKind) -> GraphQLRequest<[PageHeader]> {
        let request = GraphQLRequest(
            endpointName: "pageHeaders",
            parser: ManyParser<PageHeader>(PageHeaderParser()).parse,
            variables: [
                (.enum("kind", "PageHeaderKind", kind.apiKind)),
                (.optionalString("slug", kind.slug)),
            ],
            fragments: """
                fragment imageProps on Image {
                  url
                  metadata { height width type size }
                }

                fragment responsiveImages on ResponsiveImageVersions {
                  mdpi { ...imageProps }
                  hdpi { ...imageProps }
                  xhdpi { ...imageProps }
                  optimized { ...imageProps }
                }

                fragment tshirtImages on TshirtImageVersions {
                  regular { ...imageProps }
                  large { ...imageProps }
                  original { ...imageProps }
                }

                fragment userProps on User {
                  id
                  username
                  name
                  avatar {
                    ...tshirtImages
                  }
                  coverImage {
                    ...responsiveImages
                  }
                }
                """,
            body: """
                id
                postToken
                kind
                header
                subheader
                image { ...responsiveImages }
                ctaLink { text url }
                user { ...userProps }
                """
            )
        return request
    }

    func userPosts(username: String, before: String? = nil) -> GraphQLRequest<(PageConfig, [Post])> {
        let request = GraphQLRequest(
            endpointName: "userPostStream",
            parser: PageParser<Post>("posts", PostParser()).parse,
            variables: [
                (.string("username", username)),
                (.optionalString("before", before)),
            ],
            fragments: """
                fragment imageProps on Image {
                  url
                  metadata { height width type size }
                }

                fragment tshirtImages on TshirtImageVersions {
                  regular { ...imageProps }
                  large { ...imageProps }
                  original { ...imageProps }
                }

                fragment responsiveImages on ResponsiveImageVersions {
                  mdpi { ...imageProps }
                  hdpi { ...imageProps }
                  xhdpi { ...imageProps }
                  optimized { ...imageProps }
                }

                fragment userProps on User {
                  id
                  username
                  name
                  currentUserState { relationshipPriority }
                  settings {
                    hasCommentingEnabled hasLovesEnabled hasRepostingEnabled hasSharingEnabled
                    isCollaborateable isHireable
                  }
                  avatar {
                    ...tshirtImages
                  }
                  coverImage {
                    ...responsiveImages
                  }
                }

                fragment contentProps on ContentBlocks {
                  linkUrl
                  kind
                  data
                  links { assets }
                }

                fragment assetProps on Asset {
                  id
                  attachment { ...responsiveImages }
                }

                fragment postContent on Post {
                  content { ...contentProps }
                }

                fragment postSummary on Post {
                  id
                  token
                  createdAt
                  summary { ...contentProps }
                  author { ...userProps }
                  assets { ...assetProps }
                  postStats { lovesCount commentsCount viewsCount repostsCount }
                  currentUserState { watching loved reposted }
                }
                """,
            body: """
                next isLastPage
                posts {
                    ...postSummary
                    ...postContent
                    repostContent { ...contentProps }
                    currentUserState { loved reposted watching }
                    repostedSource {
                        ...postSummary
                    }
                }
                """
            )
        return request
    }
}
