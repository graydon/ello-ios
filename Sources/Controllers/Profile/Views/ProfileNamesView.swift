////
///  ProfileNamesView.swift
//

class ProfileNamesView: ProfileBaseView {
    struct Size {
        static let horizNameMargin: CGFloat = 10
        static let vertNameMargin: CGFloat = 5
        static let outerMargins = UIEdgeInsets(top: 19, left: 15, bottom: 20, right: 15)
    }
    static let nameFont = UIFont.defaultFont(18)
    static let usernameFont = UIFont.defaultFont()

    static func preferredHeight(nameSize: CGSize, usernameSize: CGSize, maxWidth: CGFloat) -> (CGFloat, isVertical: Bool) {
        let bothNamesWidth = nameSize.width + usernameSize.width + Size.horizNameMargin
        let maxAllowedWidth = maxWidth - Size.outerMargins.sides
        if bothNamesWidth > maxAllowedWidth {
            let height = nameSize.height + usernameSize.height + Size.vertNameMargin
            return (height, isVertical: true)
        }
        else {
            let height = max(nameSize.height, usernameSize.height)
            return (height, isVertical: false)
        }
    }

    var name: String {
        get { return nameLabel.text ?? "" }
        set {
            nameLabel.text = newValue
            nameLabel.sizeToFit()
            nameLabel.frame.size.height = 24
            setNeedsLayout()
        }
    }
    var username: String {
        get { return usernameLabel.text ?? "" }
        set {
            usernameLabel.text = newValue
            usernameLabel.sizeToFit()
            usernameLabel.frame.size.height = 20
            setNeedsLayout()
        }
    }

    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let grayLine = UIView()

    override func style() {
        backgroundColor = .white
        nameLabel.font = ProfileNamesView.nameFont
        nameLabel.textColor = .black
        usernameLabel.font = ProfileNamesView.usernameFont
        usernameLabel.textColor = .greyA
        grayLine.backgroundColor = .greyE5
    }

    override func arrange() {
        addSubview(grayLine)

        grayLine.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.bottom.equalTo(self)
            make.leading.trailing.equalTo(self).inset(ProfileBaseView.Size.grayInset)
        }

        addSubview(nameLabel)
        addSubview(usernameLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.frame.origin.y = Size.outerMargins.top

        let (_, isVertical) = ProfileNamesView.preferredHeight(nameSize: nameLabel.frame.size, usernameSize: usernameLabel.frame.size, maxWidth: frame.width)
        if isVertical {
            nameLabel.frame.origin.x = (frame.width - nameLabel.frame.width) / 2
            usernameLabel.frame.origin = CGPoint(
                x: (frame.width - usernameLabel.frame.width) / 2,
                y: nameLabel.frame.maxY + Size.vertNameMargin
                )
        }
        else {
            nameLabel.frame.origin.x = (frame.width - nameLabel.frame.width - usernameLabel.frame.width - Size.horizNameMargin) / 2
            usernameLabel.frame.origin = CGPoint(
                x: nameLabel.frame.maxX + Size.horizNameMargin,
                y: nameLabel.frame.maxY - usernameLabel.frame.height - 1
                )
        }

        for label in [nameLabel, usernameLabel] {
            label.frame.origin.x = max(Size.outerMargins.left, label.frame.origin.x)
            label.frame.size.width = min(frame.width - Size.outerMargins.sides, label.frame.size.width)
        }
    }
}

extension ProfileNamesView {
    func prepareForReuse() {
        // nothing here yet
    }
}
