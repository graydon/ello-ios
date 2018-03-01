////
///  CategoryScreen.swift
//

import SnapKit


class CategoryScreen: HomeSubviewScreen, CategoryScreenProtocol {
    struct Size {
        static let navigationBarHeight: CGFloat = 43
        static let buttonWidth: CGFloat = 40
        static let buttonMargin: CGFloat = 5
        static let gradientMidpoint: Float = 0.4
        static var categoryCardListInset: CGFloat { return CategoryCardListView.Size.spacing }
    }

    enum NavBarItems {
        case onlyGridToggle
        case all
        case none
    }

    enum Selection {
        case all
        case subscribed
        case category(Int)
    }

    typealias Usage = CategoryViewController.Usage

    weak var delegate: CategoryScreenDelegate?
    var topInsetView: UIView { return categoryCardList }
    var showSubscribed: Bool = false
    var showSeeAll: Bool = false { didSet { updateSeeAllButton() } }
    var isGridView = false {
        didSet {
            gridListButton.setImage(isGridView ? .listView : .gridView, imageStyle: .normal, for: .normal)
        }
    }

    private let usage: Usage

    init(usage: Usage) {
        self.usage = usage
        super.init(frame: .default)
    }

    required init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let categoryCardList = CategoryCardListView()
    private let iPhoneBlackBar = UIView()
    private let searchField = SearchNavBarField()
    private let searchFieldButton = UIButton()
    private let backButton = UIButton()
    private let seeAllButton = StyledButton(style: .clearWhite)
    private let seeAllGradient = CategoryScreen.generateGradientLayer()
    private let gridListButton = UIButton()
    private let shareButton = UIButton()
    private let navigationContainer = UIView()

    private var categoryCardTopConstraint: Constraint!
    private var iPhoneBlackBarTopConstraint: Constraint!
    private var backVisibleConstraint: Constraint!
    private var backHiddenConstraint: Constraint!
    private var shareVisibleConstraint: Constraint!
    private var shareHiddenConstraint: Constraint!
    private var allHiddenConstraint: Constraint!

    private var navBarVisible = true
    private var hasCategories: Bool { return !categoryCardList.categoriesInfo.isEmpty }
    private var categoryCardListTop: CGFloat {
        if navBarVisible {
            return self.navigationBar.frame.height
        }
        else if Globals.isIphoneX {
            return Globals.statusBarHeight
        }
        else {
            return 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        seeAllGradient.frame = seeAllButton.bounds
    }

    override func style() {
        super.style()
        iPhoneBlackBar.backgroundColor = .black
        backButton.setImages(.backChevron)
        shareButton.alpha = 0
        shareButton.setImage(.share, imageStyle: .normal, for: .normal)
        seeAllButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 10)
        seeAllButton.isHidden = true
    }

    override func setText() {
        navigationBar.title = ""
        seeAllButton.setTitle(InterfaceString.SeeAll, for: .normal)
    }

    override func bindActions() {
        super.bindActions()
        categoryCardList.delegate = self
        searchFieldButton.addTarget(self, action: #selector(searchFieldButtonTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        gridListButton.addTarget(self, action: #selector(gridListToggled), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
    }

    override func arrange() {
        super.arrange()
        addSubview(categoryCardList)
        seeAllButton.layer.insertSublayer(seeAllGradient, at: 0)
        addSubview(seeAllButton)
        addSubview(navigationBar)

        navigationContainer.addSubview(searchField)
        navigationContainer.addSubview(searchFieldButton)
        navigationBar.addSubview(backButton)
        navigationBar.addSubview(navigationContainer)
        navigationBar.addSubview(gridListButton)
        navigationBar.addSubview(shareButton)

        if usage == .largeNav {
            navigationBar.sizeClass = .discoverLarge
            arrangeHomeScreenNavBar(type: .discover, navigationBar: navigationBar)
        }

        if Globals.isIphoneX {
            addSubview(iPhoneBlackBar)
            iPhoneBlackBar.snp.makeConstraints { make in
                iPhoneBlackBarTopConstraint = make.top.equalTo(self).constraint
                make.leading.trailing.equalTo(self)
                make.height.equalTo(Globals.statusBarHeight + Size.navigationBarHeight)
            }
            iPhoneBlackBar.alpha = 0
        }

        categoryCardList.snp.makeConstraints { make in
            categoryCardTopConstraint = make.top.equalTo(self).constraint
            make.leading.trailing.equalTo(self)
            make.height.equalTo(CategoryCardListView.Size.height)
        }

        seeAllButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(categoryCardList).inset(Size.categoryCardListInset)
            make.trailing.equalTo(self)
        }

        backButton.snp.makeConstraints { make in
            make.leading.bottom.equalTo(navigationBar)
            make.height.equalTo(Size.navigationBarHeight)
            make.width.equalTo(36.5)
        }

        searchField.snp.makeConstraints { make in
            var insets: UIEdgeInsets
            if usage == .largeNav {
                insets = SearchNavBarField.Size.largeNavSearchInsets
            }
            else {
                insets = SearchNavBarField.Size.searchInsets
            }
            insets.top -= StatusBar.Size.height
            insets.bottom -= 1
            make.bottom.equalTo(navigationBar).inset(insets)
            make.height.equalTo(Size.navigationBarHeight - insets.tops)

            backHiddenConstraint = make.leading.equalTo(navigationBar).inset(insets).constraint
            backVisibleConstraint = make.leading.equalTo(backButton.snp.trailing).offset(insets.left).constraint

            shareHiddenConstraint = make.trailing.equalTo(gridListButton.snp.leading).offset(-insets.right).constraint
            shareVisibleConstraint = make.trailing.equalTo(shareButton.snp.leading).offset(-Size.buttonMargin).constraint
            allHiddenConstraint = make.trailing.equalTo(gridListButton.snp.trailing).offset(-Size.buttonMargin).constraint
        }
        backVisibleConstraint.deactivate()
        shareVisibleConstraint.deactivate()
        allHiddenConstraint.deactivate()

        navigationContainer.snp.makeConstraints { make in
            make.leading.equalTo(searchField).offset(-SearchNavBarField.Size.searchInsets.left)
            make.bottom.equalTo(navigationBar)
            make.height.equalTo(Size.navigationBarHeight)
            make.trailing.equalTo(gridListButton.snp.leading)
        }

        searchFieldButton.snp.makeConstraints { make in
            make.edges.equalTo(navigationContainer)
        }
        gridListButton.snp.makeConstraints { make in
            make.height.equalTo(Size.navigationBarHeight)
            make.bottom.equalTo(navigationBar)
            make.trailing.equalTo(navigationBar).offset(-Size.buttonMargin)
            make.width.equalTo(Size.buttonWidth)
        }
        shareButton.snp.makeConstraints { make in
            make.top.bottom.width.equalTo(gridListButton)
            make.trailing.equalTo(gridListButton.snp.leading)
        }

        navigationBar.snp.makeConstraints { make in
            let intrinsicHeight = navigationBar.sizeClass.height
            make.height.equalTo(intrinsicHeight - 1).priority(Priority.required)
        }
    }

    func set(categoriesInfo newValue: [CategoryCardListView.CategoryInfo], completion: @escaping Block) {
        categoryCardList.categoriesInfo = newValue
        updateSeeAllButton()

        if navBarVisible {
            completion()
            return
        }

        let seeAllButtonY = categoryCardListTop + Size.categoryCardListInset
        let originalY = categoryCardList.frame.origin.y
        categoryCardList.frame.origin.y = originalY - categoryCardList.frame.size.height
        seeAllButton.frame.origin.y = seeAllButtonY - seeAllButton.frame.height
        elloAnimate {
            self.seeAllButton.frame.origin.y = seeAllButtonY
            self.categoryCardList.frame.origin.y = originalY
        }.always(completion)
    }

    private func updateSeeAllButton() {
        let actuallyShowSeeAll = showSeeAll && hasCategories
        seeAllButton.isHidden = !actuallyShowSeeAll
        let rightInset = actuallyShowSeeAll ? seeAllButton.frame.width * CGFloat(1 - Size.gradientMidpoint) : 0
        categoryCardList.rightInset = rightInset
    }

    func toggleCategoriesList(navBarVisible: Bool, animated: Bool) {
        self.navBarVisible = navBarVisible
        elloAnimate(animated: animated) {
            self.categoryCardTopConstraint.update(offset: self.categoryCardListTop)
            self.categoryCardList.frame.origin.y = self.categoryCardListTop
            self.seeAllButton.frame.origin.y = self.categoryCardListTop + Size.categoryCardListInset

            if Globals.isIphoneX {
                let iPhoneBlackBarTop = self.categoryCardList.frame.minY - self.iPhoneBlackBar.frame.height
                self.iPhoneBlackBarTopConstraint.update(offset: iPhoneBlackBarTop)
                self.iPhoneBlackBar.frame.origin.y = iPhoneBlackBarTop
                self.iPhoneBlackBar.alpha = navBarVisible ? 0 : 1
            }
        }
    }

    func scrollToCategory(_ selection: Selection) {
        switch selection {
        case .all:
            self.categoryCardList.scrollToIndex(0, animated: true)
        case .subscribed:
            self.categoryCardList.scrollToIndex(1, animated: true)
        case let .category(index):
            let offset = showSubscribed ? 2 : 1
            self.categoryCardList.scrollToIndex(index + offset, animated: true)
        }
    }

    func selectCategory(_ selection: Selection) {
        switch selection {
        case .all:
            self.categoryCardList.selectCategory(index: 0)
        case .subscribed:
            self.categoryCardList.selectCategory(index: 1)
        case let .category(index):
            let offset = showSubscribed ? 2 : 1
            self.categoryCardList.selectCategory(index: index + offset)
        }
    }

    @objc
    func searchFieldButtonTapped() {
        delegate?.searchButtonTapped()
    }

    @objc
    func backButtonTapped() {
        delegate?.backButtonTapped()
    }

    @objc
    func gridListToggled() {
        delegate?.gridListToggled(sender: gridListButton)
    }

    @objc
    func shareTapped() {
        delegate?.shareTapped(sender: shareButton)
    }

    @objc
    func seeAllTapped() {
        delegate?.seeAllCategoriesTapped()
    }

    func setupNavBar(show: CategoryScreen.NavBarItems, back backVisible: Bool, animated: Bool) {
        let shareButtonAlpha: CGFloat
        let gridButtonAlpha: CGFloat
        switch show {
        case .onlyGridToggle:
            shareButtonAlpha = 0
            gridButtonAlpha = 1
        case .all:
            shareButtonAlpha = 1
            gridButtonAlpha = 1
        case .none:
            shareButtonAlpha = 0
            gridButtonAlpha = 0
        }

        shareHiddenConstraint.set(isActivated: show == .onlyGridToggle)
        shareVisibleConstraint.set(isActivated: show == .all)
        allHiddenConstraint.set(isActivated: show == .none)

        backButton.isHidden = !backVisible
        backVisibleConstraint.set(isActivated: backVisible)
        backHiddenConstraint.set(isActivated: !backVisible)

        elloAnimate(animated: animated) {
            self.shareButton.alpha = shareButtonAlpha
            self.gridListButton.alpha = gridButtonAlpha
            self.navigationBar.layoutIfNeeded()
        }
    }
}

extension CategoryScreen: CategoryCardListDelegate {
    func allCategoriesTapped() {
        delegate?.allCategoriesTapped()
    }

    func categoryCardSelected(_ index: Int) {
        let categoriesInfo = categoryCardList.categoriesInfo
        let info = categoriesInfo[index]

        if info.isSubscribed {
            delegate?.subscribedCategoryTapped()
        }
        else if categoriesInfo[0].isSubscribed {
            delegate?.categorySelected(index: index - 1)
        }
        else {
            delegate?.categorySelected(index: index)
        }
    }
}

extension CategoryScreen: HomeScreenNavBar {
    @objc
    func homeScreenScrollToTop() {
        delegate?.scrollToTop()
    }
}

extension CategoryScreen {
    private static func generateGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.locations = [0, NSNumber(value: CategoryScreen.Size.gradientMidpoint), 1]
        layer.colors = [
            UIColor(hex: 0x000000, alpha: 0).cgColor,
            UIColor(hex: 0x000000, alpha: 1).cgColor,
            UIColor(hex: 0x000000, alpha: 1).cgColor,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }
}
