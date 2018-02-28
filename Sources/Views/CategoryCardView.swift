////
///  CategoryCardView.swift
//

class CategoryCardView: View {
    static let selectedAlpha: CGFloat = 0.8
    static let normalAlpha: CGFloat = 0.6
    static let darkAlpha: CGFloat = 0.8
    static let fullAlpha: CGFloat = 1.0

    let info: CategoryCardListView.CategoryInfo
    var isSelected: Bool {
        set {
            _selected = newValue
            let alpha: CGFloat
            if newValue, info.isAll {
                alpha = CategoryCardView.fullAlpha
            }
            else if newValue {
                alpha = CategoryCardView.selectedAlpha
            }
            else if info.isAll {
                alpha = CategoryCardView.darkAlpha
            }
            else {
                alpha = CategoryCardView.normalAlpha
            }

            elloAnimate {
                self.overlay.alpha = alpha
            }
        }
        get { return _selected }
    }

    var overlayAlpha: CGFloat {
        get { return overlay.alpha }
        set { overlay.alpha = newValue }
    }

    let button = UIButton()
    private let overlay = UIView()
    private var _selected = false

    init(info: CategoryCardListView.CategoryInfo) {
        self.info = info
        super.init(frame: .default)
    }

    required init(frame: CGRect) {
        fatalError("use init(info:)")
    }

    required init?(coder: NSCoder) {
        fatalError("use init(info:)")
    }

    override func style() {
        backgroundColor = .white

        overlay.backgroundColor = .black
        if info.isSubscribed {
            overlay.alpha = CategoryCardView.normalAlpha
        }
        else if info.isAll {
            overlay.alpha = CategoryCardView.darkAlpha
        }
        else {
            overlay.alpha = CategoryCardView.normalAlpha
        }

        button.titleLabel?.numberOfLines = 0
        let attributedString = NSAttributedString(
            button: info.title,
            style: info.isSubscribed ? .whiteBoldUnderlined : .clearWhite,
            state: .normal)
        button.setAttributedTitle(attributedString, for: .normal)
    }

    override func arrange() {
        if let url = info.imageURL {
            let imageView = UIImageView()
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.pin_setImage(from: url)
            addSubview(imageView)
            imageView.snp.makeConstraints { $0.edges.equalTo(self) }
        }
        else if info.isSubscribed {
            let imageView = UIImageView(image: UIImage(named: "subscribed-background"))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            addSubview(imageView)
            imageView.snp.makeConstraints { $0.edges.equalTo(self) }
        }

        addSubview(overlay)
        addSubview(button)

        overlay.snp.makeConstraints { $0.edges.equalTo(self) }
        button.snp.makeConstraints { $0.edges.equalTo(self).inset(5) }
    }
}

extension CategoryCardView {
    func addTarget(_ target: Any?, action: Selector) {
        button.addTarget(target, action: action, for: .touchUpInside)
    }
}
