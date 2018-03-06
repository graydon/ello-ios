////
///  CategoryCardListView.swift
//

protocol CategoryCardListDelegate: class {
    func allCategoriesTapped()
    func categoryCardSelected(_ index: Int)
}

class CategoryCardListView: View {
    struct Size {
        static let height: CGFloat = 70
        static let smallCardSize: CGSize = CGSize(width: 50, height: 68)
        static let cardSize: CGSize = CGSize(width: 100, height: 68)
        static let spacing: CGFloat = 1
    }

    struct CategoryInfo {
        enum Kind {
            case all
            case subscribed
            case category
        }

        let title: String
        let kind: Kind
        let imageURL: URL?

        var isAll: Bool { return kind == .all }
        var isSubscribed: Bool { return kind == .subscribed }
    }

    weak var delegate: CategoryCardListDelegate?

    var categoriesInfo: [CategoryInfo] = [] {
        didSet { updateCategoryViews() }
    }

    private var buttonIndexLookup: [UIButton: Int] = [:]
    private var categoryViews: [CategoryCardView] = []
    private let remainderView = UIView()
    private let remainderGradient = CategoryCardListView.generateGradientLayer()
    private let scrollView = UIScrollView()
    private var scrollViewBackground: UIView?

    var rightInset: CGFloat {
        get { return scrollView.contentInset.right }
        set {
            scrollView.contentInset.right = newValue
            scrollView.scrollIndicatorInsets.right = newValue
            setNeedsLayout()
        }
    }

    override func style() {
        backgroundColor = .white
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
    }

    override func arrange() {
        remainderView.layer.addSublayer(remainderGradient)
        remainderView.isHidden = true
        addSubview(remainderView)
        addSubview(scrollView)

        remainderView.snp.makeConstraints { make in
            make.trailing.equalTo(scrollView)
            make.top.bottom.equalTo(scrollView).inset(Size.spacing)
            make.leading.equalTo(scrollView).offset(Size.smallCardSize.width)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    @objc
    func allCategoriesTapped() {
        delegate?.allCategoriesTapped()
    }

    @objc
    func categoryButtonTapped(_ button: UIButton) {
        guard let index = buttonIndexLookup[button] else { return }
        delegate?.categoryCardSelected(index)
    }

    func scrollToIndex(_ index: Int, animated: Bool) {
        guard let view = categoryViews.safeValue(index) else { return }
        layoutIfNeeded()

        let left = view.frame.minX
        let right = view.frame.maxX - frame.width
        if scrollView.contentOffset.x > left {
            scrollView.setContentOffset(CGPoint(x: left, y: 0), animated: animated)
        }
        else if scrollView.contentOffset.x < right {
            scrollView.setContentOffset(CGPoint(x: right, y: 0), animated: animated)
        }
    }

    func selectCategory(index: Int) {
        guard let view = categoryViews.safeValue(index) else { return }

        for card in categoryViews where card != view {
            card.isSelected = false
        }

        view.isSelected = true
    }

    private func updateCategoryViews() {
        self.scrollViewBackground?.removeFromSuperview()
        for view in categoryViews {
            view.removeFromSuperview()
        }

        buttonIndexLookup = [:]

        let allCategories = CategoryCardView(info: CategoryInfo(title: InterfaceString.Discover.AllCategories, kind: .all, imageURL: nil))
        allCategories.overlayAlpha = CategoryCardView.darkAlpha
        allCategories.snp.makeConstraints { make in
            make.size.equalTo(Size.smallCardSize)
        }
        allCategories.addTarget(self, action: #selector(allCategoriesTapped))

        categoryViews = [allCategories] + categoriesInfo.enumerated().map { (index, info) in
            let view = categoryView(index: index, info: info)
            view.snp.makeConstraints { make in
                make.size.equalTo(Size.cardSize)
            }
            return view
        }

        var prevView: UIView? = nil
        for view in categoryViews {
            scrollView.addSubview(view)

            view.snp.makeConstraints { make in
                make.centerY.equalTo(scrollView)

                if let prevView = prevView {
                    make.leading.equalTo(prevView.snp.trailing).offset(Size.spacing)
                }
                else {
                    make.leading.equalTo(scrollView.snp.leading)
                }
            }

            prevView = view
        }

        if let prevView = prevView {
            let scrollViewBackground = UIView()
            scrollViewBackground.backgroundColor = .white
            scrollView.insertSubview(scrollViewBackground, at: 0)
            scrollViewBackground.snp.makeConstraints { make in
                make.leading.trailing.equalTo(scrollView)
                make.top.bottom.equalTo(prevView).inset(-Size.spacing)
            }
            self.scrollViewBackground = scrollViewBackground

            prevView.snp.makeConstraints { make in
                make.trailing.equalTo(scrollViewBackground).offset(-Size.spacing)
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutIfNeeded()
        remainderGradient.frame = remainderView.bounds

        let calculate: (UIView) -> CGFloat = { self.frame.width - $0.frame.maxX - Size.spacing - self.scrollView.contentInset.right }
        if let lastCard = categoryViews.last, let remWidth = categoryViews.last.map(calculate), remWidth > 0 {
        //     remainderView.frame = CGRect(
        //         x: Size.spacing,
        //         y: lastCard.frame.minY,
        //         width: frame.width - 2 * Size.spacing,
        //         height: lastCard.frame.height
        //         )
            remainderView.isHidden = false
        //     if remainderGradient.superlayer == nil {
        //         remainderView.layer.addSublayer(remainderGradient)
        //     }
        }
        else {
            remainderView.isHidden = true
        //     if remainderGradient.superlayer != nil {
        //         remainderGradient.removeFromSuperlayer()
        //     }
        }
    }

    private func categoryView(index: Int, info: CategoryInfo) -> CategoryCardView {
        let card = CategoryCardView(info: info)
        card.addTarget(self, action: #selector(categoryButtonTapped(_:)))
        buttonIndexLookup[card.button] = index
        return card
    }
}

extension CategoryCardListView {
    private static func generateGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.locations = [0, NSNumber(value: CategoryScreen.Size.gradientMidpoint), 1]
        layer.colors = [
            UIColor(hex: 0xD300BD, alpha: 1).cgColor,
            UIColor(hex: 0xd200ff, alpha: 1).cgColor,
            UIColor(hex: 0x0063ff, alpha: 1).cgColor,
            UIColor(hex: 0x00ffc1, alpha: 1).cgColor,
            UIColor(hex: 0x0BFF66, alpha: 1).cgColor,
            UIColor(hex: 0x22FF51, alpha: 1).cgColor,
        ]
        layer.locations = [
            0,
            0.08,
            0.40,
            0.70,
            0.96,
            1,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.51)
        layer.endPoint = CGPoint(x: 1, y: 0.49)
        return layer
    }
}
