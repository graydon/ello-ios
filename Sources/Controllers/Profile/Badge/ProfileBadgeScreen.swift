////
///  ProfileBadgeScreen.swift
//

import SnapKit


class ProfileBadgeScreen: Screen, ProfileBadgeScreenProtocol {
    struct Size {
        static let learnMoreSpacing: CGFloat = 20
    }

    weak var delegate: ProfileBadgeScreenDelegate?
    let title: String
    let caption: String

    private let titleLabel = StyledLabel(style: .largeWhite)
    private let learnMoreButton = StyledButton(style: .grayUnderlined)

    init(title: String, caption: String) {
        self.title = title
        self.caption = caption
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(frame: CGRect) {
        fatalError("use init(title:)")
    }

    override func style() {
        backgroundColor = .clear
    }

    override func bindActions() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        addGestureRecognizer(gesture)
        learnMoreButton.addTarget(self, action: #selector(learnMoreTapped), for: .touchUpInside)
    }

    override func setText() {
        titleLabel.text = title
        learnMoreButton.title = caption
    }

    override func arrange() {
        addSubview(titleLabel)
        addSubview(learnMoreButton)

        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(self)
        }

        learnMoreButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(Size.learnMoreSpacing)
        }
    }

    @objc
    func dismiss() {
        delegate?.dismiss()
    }

    @objc
    func learnMoreTapped() {
        delegate?.learnMoreTapped()
    }
}
