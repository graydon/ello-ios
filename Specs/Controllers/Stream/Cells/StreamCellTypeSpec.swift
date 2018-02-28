////
///  StreamCellTypeSpec.swift
//

@testable import Ello
import Quick
import Nimble


class StreamCellTypeSpec: QuickSpec {

    override func spec() {
        describe("StreamCellType") {

            let expectations: [(
                String,
                type: StreamCellType,
                name: String,
                isSelectable: Bool,
                classType: AnyClass,
                oneColumnHeight: CGFloat?,
                multiColumnHeight: CGFloat?,
                isFullWidth: Bool,
                isCollapsable: Bool)] = [
                    (".categorySubscribeCard", type: .categorySubscribeCard, name: CategoryCardCell.reuseIdentifier, isSelectable: true, classType: CategoryCardCell.self, oneColumnHeight: nil, multiColumnHeight: nil, isFullWidth: false, isCollapsable: false),
                    (".onboardingCategoryCard", type: .onboardingCategoryCard, name: CategoryCardCell.selectableReuseIdentifier, isSelectable: true, classType: CategoryCardCell.self, oneColumnHeight: nil, multiColumnHeight: nil, isFullWidth: false, isCollapsable: false),
                    (".categoryList", type: .categoryList, name: CategoryListCell.reuseIdentifier, isSelectable: false, classType: CategoryListCell.self, oneColumnHeight: 45, multiColumnHeight: 45, isFullWidth: true, isCollapsable: false),
                    (".commentHeader", type: .commentHeader, name: CommentHeaderCell.reuseIdentifier, isSelectable: false, classType: CommentHeaderCell.self, oneColumnHeight: 60, multiColumnHeight: 60, isFullWidth: true, isCollapsable: false),
                    (".createComment", type: .createComment, name: StreamCreateCommentCell.reuseIdentifier, isSelectable: true, classType: StreamCreateCommentCell.self, oneColumnHeight: 75, multiColumnHeight: 75, isFullWidth: true, isCollapsable: false),
                    (".embed", type: .embed(data: nil), name: StreamEmbedCell.reuseEmbedIdentifier, isSelectable: false, classType: StreamEmbedCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: false, isCollapsable: true),
                    (".editorial", type: .editorial(.post), name: Editorial.Kind.post.reuseIdentifier, isSelectable: false, classType: EditorialPostCell.self, oneColumnHeight: 376, multiColumnHeight: 376, isFullWidth: true, isCollapsable: false),
                    (".streamFooter", type: .streamFooter, name: StreamFooterCell.reuseIdentifier, isSelectable: false, classType: StreamFooterCell.self, oneColumnHeight: 44, multiColumnHeight: 44, isFullWidth: false, isCollapsable: false),
                    (".streamHeader", type: .streamHeader, name: StreamHeaderCell.reuseIdentifier, isSelectable: true, classType: StreamHeaderCell.self, oneColumnHeight: 70, multiColumnHeight: 60, isFullWidth: false, isCollapsable: false),
                    (".image", type: .image(data: nil), name: StreamImageCell.reuseIdentifier, isSelectable: false, classType: StreamImageCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: false, isCollapsable: true),
                    (".inviteFriends", type: .inviteFriends, name: StreamInviteFriendsCell.reuseIdentifier, isSelectable: true, classType: StreamInviteFriendsCell.self, oneColumnHeight: 60, multiColumnHeight: 60, isFullWidth: true, isCollapsable: false),
                    (".onboardingInviteFriends", type: .onboardingInviteFriends, name: StreamInviteFriendsCell.reuseIdentifier, isSelectable: true, classType: StreamInviteFriendsCell.self, oneColumnHeight: 60, multiColumnHeight: 60, isFullWidth: true, isCollapsable: false),
                    (".emptyStream", type: .emptyStream(height: 123), name: SimpleMessageCell.reuseEmbedIdentifier, isSelectable: false, classType: SimpleMessageCell.self, oneColumnHeight: 123, multiColumnHeight: 123, isFullWidth: true, isCollapsable: false),
                    (".error", type: .error(message: "test"), name: SimpleMessageCell.reuseEmbedIdentifier, isSelectable: false, classType: SimpleMessageCell.self, oneColumnHeight: 282, multiColumnHeight: 282, isFullWidth: true, isCollapsable: false),
                    (".noPosts", type: .noPosts, name: NoPostsCell.reuseIdentifier, isSelectable: false, classType: NoPostsCell.self, oneColumnHeight: 215, multiColumnHeight: 215, isFullWidth: true, isCollapsable: false),
                    (".notification", type: .notification, name: NotificationCell.reuseIdentifier, isSelectable: true, classType: NotificationCell.self, oneColumnHeight: 117, multiColumnHeight: 60, isFullWidth: true, isCollapsable: false),
                    (".promotionalHeader", type: .promotionalHeader, name: PromotionalHeaderCell.reuseIdentifier, isSelectable: false, classType: PromotionalHeaderCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: true, isCollapsable: false),
                    (".placeholder", type: .placeholder, name: "Placeholder", isSelectable: false, classType: UICollectionViewCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: false, isCollapsable: false),
                    (".profileHeader", type: .profileHeader, name: ProfileHeaderCell.reuseIdentifier, isSelectable: false, classType: ProfileHeaderCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: true, isCollapsable: false),
                    (".profileHeaderGhost", type: .profileHeaderGhost, name: ProfileHeaderGhostCell.reuseIdentifier, isSelectable: false, classType: ProfileHeaderGhostCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: true, isCollapsable: false),
                    (".search", type: .search(placeholder: "cats"), name: SearchStreamCell.reuseIdentifier, isSelectable: false, classType: SearchStreamCell.self, oneColumnHeight: 68, multiColumnHeight: 68, isFullWidth: true, isCollapsable: false),
                    (".seeMoreComments", type: .seeMoreComments, name: StreamSeeMoreCommentsCell.reuseIdentifier, isSelectable: true, classType: StreamSeeMoreCommentsCell.self, oneColumnHeight: 60, multiColumnHeight: 60, isFullWidth: true, isCollapsable: false),
                    (".spacer", type: .spacer(height: 50), name: "StreamSpacerCell", isSelectable: false, classType: UICollectionViewCell.self, oneColumnHeight: 50, multiColumnHeight: 50, isFullWidth: false, isCollapsable: false),
                    (".fullWidthSpacer", type: .fullWidthSpacer(height: 125), name: "StreamSpacerCell", isSelectable: false, classType: UICollectionViewCell.self, oneColumnHeight: 125, multiColumnHeight: 125, isFullWidth: true, isCollapsable: false),
                    (".streamLoading", type: .streamLoading, name: StreamLoadingCell.reuseIdentifier, isSelectable: false, classType: StreamLoadingCell.self, oneColumnHeight: 50, multiColumnHeight: 50, isFullWidth: true, isCollapsable: false),
                    (".text", type: .text(data: nil), name: StreamTextCell.reuseIdentifier, isSelectable: false, classType: StreamTextCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: false, isCollapsable: true),
                    (".header", type: .header(""), name: TextHeaderCell.reuseIdentifier, isSelectable: false, classType: TextHeaderCell.self, oneColumnHeight: 30, multiColumnHeight: 30, isFullWidth: true, isCollapsable: false),
                    (".tallHeader", type: .tallHeader(nil), name: TextHeaderCell.reuseIdentifier, isSelectable: false, classType: TextHeaderCell.self, oneColumnHeight: 75, multiColumnHeight: 75, isFullWidth: true, isCollapsable: false),
                    (".toggle", type: .toggle, name: StreamToggleCell.reuseIdentifier, isSelectable: true, classType: StreamToggleCell.self, oneColumnHeight: 40, multiColumnHeight: 40, isFullWidth: false, isCollapsable: false),
                    (".unknown", type: .unknown, name: "StreamUnknownCell", isSelectable: false, classType: UICollectionViewCell.self, oneColumnHeight: 0, multiColumnHeight: 0, isFullWidth: false, isCollapsable: false),
                    (".userAvatars", type: .userAvatars, name: UserAvatarsCell.reuseIdentifier, isSelectable: false, classType: UserAvatarsCell.self, oneColumnHeight: 50, multiColumnHeight: 50, isFullWidth: true, isCollapsable: false),
                    (".userListItem", type: .userListItem, name: UserListItemCell.reuseIdentifier, isSelectable: true, classType: UserListItemCell.self, oneColumnHeight: 85, multiColumnHeight: 85, isFullWidth: true, isCollapsable: false),
            ]

            for (desc, type, name, selectable, classType, oneColumnHeight, multiColumnHeight, isFullWidth, isCollapsable) in expectations {

                it("\(desc) returns correct values"){
                    // TODO: figure out a way to test for confgure
                    expect(type.reuseIdentifier) == name
                    expect(type.isSelectable) == selectable
                    expect(type.classType) === classType
                    if let oneColumnHeight = oneColumnHeight {
                        expect(type.oneColumnHeight) == oneColumnHeight
                    }
                    if let multiColumnHeight = multiColumnHeight {
                        expect(type.multiColumnHeight) == multiColumnHeight
                    }
                    expect(type.isFullWidth) == isFullWidth
                    expect(type.isCollapsable) == isCollapsable
                }
            }
        }
    }
}
