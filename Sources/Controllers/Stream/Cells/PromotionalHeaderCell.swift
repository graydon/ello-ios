////
///  PromotionalHeaderCell.swift
//

import SnapKit
import FLAnimatedImage


class PromotionalHeaderCell: CollectionViewCell {
    static let reuseIdentifier = "PromotionalHeaderCell"
    typealias Style = PageHeader.Kind

    struct Config {
        var style: Style = .category
        var title: String = ""
        var tracking: String = ""
        var body: String?
        var imageURL: URL?
        var user: User?
        var isSponsored = false
        var isSubscribed = false
        var callToAction: String?
        var callToActionURL: URL?

        var hasHtml: Bool {
            switch style {
            case .editorial, .artistInvite: return true
            case .category, .generic: return false
            }
        }
    }

    struct Size {
        static let defaultMargin: CGFloat = 15
        static let topMargin: CGFloat = 25
        static let bodySpacing: CGFloat = 24
        static let stackedMargin: CGFloat = 6
        static let lineTopMargin: CGFloat = 4
        static let lineHeight: CGFloat = 2
        static let lineInset: CGFloat = 0
        static let avatarMargin: CGFloat = 10
        static let avatarSize: CGFloat = 30
        static let minBodyHeight: CGFloat = 30
        static let circleBottomInset: CGFloat = 10
        static let failImageWidth: CGFloat = 140
        static let failImageHeight: CGFloat = 160
        static let subscribeIconSpacing: CGFloat = 10
    }

    private let imageView = FLAnimatedImageView()
    private let imageOverlay = UIView()
    private let titleLabel = UILabel()
    private let titleUnderlineView = UIView()
    private let bodyLabel = UILabel()
    private let bodyWebView = ElloWebView()
    private let callToActionButton = UIButton()
    private let postedByButton = UIButton()
    private let postedByAvatar = AvatarButton()
    private let circle = PulsingCircle()
    private let failImage = UIImageView()
    private let failBackgroundView = UIView()

    private var titleCenteredConstraint: Constraint!
    private var titleLeftConstraint: Constraint!
    private var postedByButtonAlignedConstraint: Constraint!
    private var postedByButtonStackedConstraint: Constraint!

    private var imageSize: CGSize?
    private var aspectRatio: CGFloat? {
        guard let imageSize = imageSize else { return nil }
        return imageSize.width / imageSize.height
    }

    private var callToActionURL: URL?
    private let subscribedIcon = UIImageView()

    var config: Config = Config() {
        didSet {
            updateConfig()
        }
    }

    override func style() {
        subscribedIcon.setInterfaceImage(.circleCheckLarge, style: .green)
        titleLabel.numberOfLines = 0
        titleUnderlineView.backgroundColor = .white
        bodyLabel.numberOfLines = 0
        bodyWebView.scrollView.isScrollEnabled = false
        bodyWebView.scrollView.scrollsToTop = false
        bodyWebView.isUserInteractionEnabled = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        callToActionButton.titleLabel?.numberOfLines = 0
        failBackgroundView.backgroundColor = .white
    }

    override func bindActions() {
        bodyWebView.delegate = self
        callToActionButton.addTarget(self, action: #selector(callToActionTapped), for: .touchUpInside)
        postedByButton.addTarget(self, action: #selector(postedByTapped), for: .touchUpInside)
        postedByAvatar.addTarget(self, action: #selector(postedByTapped), for: .touchUpInside)
    }

    override func arrange() {
        contentView.addSubview(circle)
        contentView.addSubview(failBackgroundView)
        contentView.addSubview(failImage)

        contentView.addSubview(imageView)
        contentView.addSubview(imageOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(titleUnderlineView)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(bodyWebView)
        contentView.addSubview(callToActionButton)
        contentView.addSubview(postedByButton)
        contentView.addSubview(postedByAvatar)
        contentView.addSubview(subscribedIcon)

        circle.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        failBackgroundView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        failImage.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        imageOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp.makeConstraints { make in
            titleCenteredConstraint = make.centerX.equalTo(contentView).priority(Priority.high).constraint
            titleLeftConstraint = make.leading.equalTo(contentView).inset(Size.defaultMargin).priority(Priority.low).constraint
            make.leading.greaterThanOrEqualTo(contentView).inset(Size.defaultMargin)
            make.trailing.lessThanOrEqualTo(contentView).inset(Size.defaultMargin)
            make.top.equalTo(contentView).offset(Size.topMargin)
        }

        subscribedIcon.snp.makeConstraints { make in
            make.trailing.equalTo(titleLabel.snp.leading).offset(-Size.subscribeIconSpacing)
            make.centerY.equalTo(titleLabel)
        }

        titleUnderlineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel).inset(Size.lineInset)
            make.top.equalTo(titleLabel.snp.bottom).offset(Size.lineTopMargin)
            make.height.equalTo(Size.lineHeight)
        }

        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Size.bodySpacing)
            make.leading.trailing.equalTo(contentView).inset(Size.defaultMargin)
        }

        bodyWebView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Size.bodySpacing)
            make.bottom.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(Size.defaultMargin)
        }

        callToActionButton.snp.makeConstraints { make in
            make.leading.equalTo(contentView).inset(Size.defaultMargin)
            make.trailing.lessThanOrEqualTo(contentView).inset(Size.defaultMargin)
        }

        postedByButton.snp.makeConstraints { make in
            make.trailing.equalTo(postedByAvatar.snp.leading).offset(-Size.avatarMargin)
            make.centerY.equalTo(postedByAvatar).offset(3)
            postedByButtonAlignedConstraint = make.top.equalTo(callToActionButton).priority(Priority.high).constraint
            postedByButtonStackedConstraint = make.top.equalTo(callToActionButton.snp.bottom).offset(Size.stackedMargin).priority(Priority.low).constraint
        }

        postedByAvatar.snp.makeConstraints { make in
            make.width.height.equalTo(Size.avatarSize)
            make.trailing.equalTo(contentView).inset(Size.avatarMargin)
            make.bottom.equalTo(contentView).inset(Size.avatarMargin)
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if callToActionButton.frame.intersects(postedByButton.frame) {
            // frames need to stack vertically
            postedByButtonAlignedConstraint.update(priority: Priority.low)
            postedByButtonStackedConstraint.update(priority: Priority.high)
            setNeedsLayout()
        }
        else if callToActionButton.frame.maxX < postedByButton.frame.minX && callToActionButton.frame.maxY < postedByButton.frame.minY {
            // frames should be restored to horizontal arrangement
            postedByButtonAlignedConstraint.update(priority: Priority.high)
            postedByButtonStackedConstraint.update(priority: Priority.low)
            setNeedsLayout()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.config = Config()
    }

    private func updateConfig() {
        titleLabel.attributedText = config.attributedTitle
        bodyLabel.attributedText = config.attributedBody

        if let html = config.html {
            let fullHtml = StreamTextCellHTML.editorialHTML(html)
            bodyWebView.loadHTMLString(fullHtml, baseURL: URL(string: "/"))
        }

        setImageURL(config.imageURL)
        postedByAvatar.setUserAvatarURL(config.user?.avatarURL())
        postedByButton.setAttributedTitle(config.attributedPostedBy, for: .normal)
        callToActionURL = config.callToActionURL
        callToActionButton.setAttributedTitle(config.attributedCallToAction, for: .normal)

        if config.style == .category {
            titleUnderlineView.isVisible = true
            titleCenteredConstraint.update(priority: Priority.high)
            titleLeftConstraint.update(priority: Priority.low)
        }
        else {
            titleUnderlineView.isHidden = true
            titleCenteredConstraint.update(priority: Priority.low)
            titleLeftConstraint.update(priority: Priority.high)
        }

        subscribedIcon.isVisible = config.isSubscribed
    }

    func setImageURL(_ url: URL?) {
        guard let url = url else {
            imageView.pin_cancelImageDownload()
            imageView.image = nil
            return
        }

        imageView.image = nil
        imageView.alpha = 0
        circle.pulse()
        failImage.isHidden = true
        failImage.alpha = 0
        imageView.backgroundColor = .white
        loadImage(url)
    }

    func setImage(_ image: UIImage) {
        imageView.pin_cancelImageDownload()
        imageView.image = image
        imageView.alpha = 1
        failImage.isHidden = true
        failImage.alpha = 0
        imageView.backgroundColor = .white
    }
}

extension PromotionalHeaderCell {

    @objc
    func postedByTapped() {
        Tracker.shared.categoryHeaderPostedBy(config.tracking)

        let responder: UserResponder? = findResponder()
        responder?.userTappedAuthor(cell: self)
    }

    @objc
    func callToActionTapped() {
        guard let url = callToActionURL else { return }
        Tracker.shared.categoryHeaderCallToAction(config.tracking)
        let request = URLRequest(url: url)
        ElloWebViewHelper.handle(request: request, origin: self)
    }
}

private extension PromotionalHeaderCell {

    func loadImage(_ url: URL) {
        guard url.scheme?.isEmpty == false else {
            if let urlWithScheme = URL(string: "https:\(url.absoluteString)") {
                loadImage(urlWithScheme)
            }
            return
        }

        imageView.pin_setImage(from: url) { [weak self] result in
            guard let `self` = self else { return }

            guard result.hasImage else {
                self.imageLoadFailed()
                return
            }

            self.imageSize = result.imageSize

            if result.resultType != .memoryCache {
                self.imageView.alpha = 0
                elloAnimate {
                    self.imageView.alpha = 1
                }.done {
                    self.circle.stopPulse()
                }
            }
            else {
                self.imageView.alpha = 1
                self.circle.stopPulse()
            }

            self.layoutIfNeeded()
        }
    }

    func imageLoadFailed() {
        failImage.isVisible = true
        failBackgroundView.isVisible = true
        circle.stopPulse()
        imageSize = nil
        UIView.animate(withDuration: 0.15, animations: {
            self.failImage.alpha = 1.0
            self.imageView.backgroundColor = UIColor.greyF1
            self.failBackgroundView.backgroundColor = UIColor.greyF1
            self.imageView.alpha = 1.0
            self.failBackgroundView.alpha = 1.0
        })
    }
}

extension PromotionalHeaderCell: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let scheme = request.url?.scheme, scheme == "default" {
            // let responder: StreamCellResponder? = findResponder()
            // responder?.streamCellTapped(cell: self)
            return false
        }
        else {
            return ElloWebViewHelper.handle(request: request, origin: self)
        }
    }
}

extension PromotionalHeaderCell.Config {

    var attributedTitle: NSAttributedString {
        switch style {
        case .category: return NSAttributedString(title, color: .white, font: .regularBlackFont(16), alignment: .center)
        case .generic, .editorial, .artistInvite: return NSAttributedString(title, color: .white, font: .regularBlackFont(32))
        }
    }

    var attributedBody: NSAttributedString? {
        guard let body = body, !hasHtml else { return nil }

        switch style {
        case .category: return NSAttributedString(body, color: .white)
        case .generic, .editorial, .artistInvite: return NSAttributedString(body, color: .white, font: .defaultFont(18))
        }
    }

    var html: String? {
        guard let body = body, hasHtml else { return nil}

        return body
    }

    var attributedPostedBy: NSAttributedString? {
        guard let user = user else { return nil }

        let postedBy = isSponsored == true ? InterfaceString.Category.SponsoredBy : InterfaceString.Category.PostedBy
        let title = NSAttributedString(postedBy, color: .white) + NSAttributedString(user.atName, color: .white, underlineStyle: .styleSingle)
        return title
    }

    var attributedCallToAction: NSAttributedString? {
        guard let callToAction = callToAction else { return nil }

        return NSAttributedString(callToAction, color: .white, underlineStyle: .styleSingle)
   }
}

extension PromotionalHeaderCell.Config {

    init(pageHeader: PageHeader, isSubscribed: Bool) {
        self.init()

        style = pageHeader.kind
        title = pageHeader.header
        body = pageHeader.subheader
        tracking = "general"
        imageURL = pageHeader.tileURL
        user = pageHeader.user
        callToAction = pageHeader.ctaCaption
        callToActionURL = pageHeader.ctaURL
        isSponsored = pageHeader.isSponsored
        self.isSubscribed = isSubscribed
    }
}

extension PromotionalHeaderCell {
    class Specs {
        weak var target: PromotionalHeaderCell!
        var postedByAvatar: AvatarButton! { return target.postedByAvatar }

        init(_ target: PromotionalHeaderCell) {
            self.target = target
        }
    }

    func specs() -> Specs {
        return Specs(self)
    }
}
