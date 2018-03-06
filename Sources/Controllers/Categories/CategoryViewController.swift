////
///  CategoryViewController.swift
//

import PromiseKit


final class CategoryViewController: StreamableViewController {
    override func trackerName() -> String? { return "Discover" }
    override func trackerProps() -> [String: Any]? {
        guard
            case let .category(slug) = categorySelection
        else { return nil }
        return ["category": slug]
    }
    override func trackerStreamInfo() -> (String, String?)? {
        if let streamId = category?.id {
            return ("category", streamId)
        }
        return nil
    }

    private var _mockScreen: CategoryScreenProtocol?
    var screen: CategoryScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return fetchScreen(_mockScreen) }
    }

    var category: Category?
    var categorySelection: Category.Selection = .all
    private var prevSelection: Category.Selection?
    var subscribedCategories: [Category]?
    var pageHeader: PageHeader?
    var generator: CategoryGenerator!
    var userDidScroll: Bool = false
    var hasSubscribedCategory: Bool {
        guard let categoryIds = currentUser?.followedCategoryIds else {
            return false
        }
        return categoryIds.count > 0
    }
    private let usage: Usage

    enum Usage {
        case `default`
        case largeNav
    }

    var showBackButton: Bool {
        if parent is HomeViewController {
            return false
        }
        return !isRootViewController()
    }

    convenience init(category: Category, usage: Usage = .default) {
        self.init(slug: category.slug, name: category.name, usage: usage)
        self.category = category
    }

    init(slug: String? = nil, name: String? = nil, usage: Usage = .default) {
        self.usage = usage
        if let slug = slug {
            self.categorySelection = .category(slug)
        }
        else {
            self.categorySelection = .all
        }
        super.init(nibName: nil, bundle: nil)
        self.title = name

        self.generator = CategoryGenerator(
            selection: categorySelection,
            currentUser: currentUser,
            destination: self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        generator.currentUser = currentUser
        if isViewLoaded {
            screen.showSeeAll = currentUser != nil

            if let subscribedCategories = subscribedCategories,
                let currentUser = currentUser,
                Set(subscribedCategories.map { $0.id }) != currentUser.followedCategoryIds
            {
                reloadCurrentCategory()
            }
        }
    }

    override func loadView() {
        let screen = CategoryScreen(usage: usage)
        screen.isGridView = StreamKind.categories.isGridView
        screen.delegate = self
        screen.showSeeAll = currentUser != nil

        view = screen
        viewContainer = screen.streamContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        screen.setupNavBar(back: showBackButton, animated: false)

        ElloHUD.showLoadingHudInView(streamViewController.view)

        streamViewController.streamKind = generator.streamKind
        streamViewController.initialLoadClosure = { [weak self] in self?.loadCategory(reload: false, reloadCategories: true) }
        streamViewController.reloadClosure = { [weak self] in self?.reloadCurrentCategory() }
        streamViewController.toggleClosure = { [weak self] isGridView in self?.toggleGrid(isGridView) }

        self.loadCategory(reload: false, reloadCategories: true)
    }

    private func updateInsets() {
        updateInsets(navBar: screen.topInsetView)

        if !userDidScroll {
            streamViewController.scrollToTop(animated: true)
        }
    }

    override func showNavBars(animated: Bool) {
        super.showNavBars(animated: animated)
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint, animated: animated)
        screen.toggleCategoriesList(navBarVisible: true, animated: animated)
        updateInsets()
    }

    override func hideNavBars(animated: Bool) {
        super.hideNavBars(animated: animated)
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint, animated: animated)
        screen.toggleCategoriesList(navBarVisible: false, animated: animated)
        updateInsets()
    }

    func toggleGrid(_ isGridView: Bool) {
        generator.toggleGrid()
    }

    override func streamViewWillBeginDragging(scrollView: UIScrollView) {
        super.streamViewWillBeginDragging(scrollView: scrollView)
        userDidScroll = true
    }

    override func streamViewInfiniteScroll() -> Promise<[JSONAble]>? {
        return generator.loadNextPage()
    }
}

private extension CategoryViewController {

    func loadCategory(reload: Bool, reloadCategories: Bool) {
        if reload {
            replacePlaceholder(type: .promotionalHeader, items: [])
            replacePlaceholder(type: .streamItems, items: [StreamCellItem(type: .streamLoading)])
        }

        if let categoryName = category?.name {
            title = categoryName
        }
        else {
            title = InterfaceString.Discover.Title
        }

        pageHeader = nil
        generator.load(reload: reload, reloadCategories: reloadCategories ?? reload)
    }

    func reloadCurrentCategory() {
        ElloHUD.showLoadingHudInView(streamViewController.view)
        screen.categoriesLoaded = false
        pageHeader = nil
        generator.load(reload: true, reloadCategories: true)
    }
}

// MARK: CategoryViewController: StreamDestination
extension CategoryViewController: CategoryStreamDestination, StreamDestination {

    var isPagingEnabled: Bool {
        get { return streamViewController.isPagingEnabled }
        set { streamViewController.isPagingEnabled = newValue }
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping Block) {
        streamViewController.doneLoading()

        streamViewController.replacePlaceholder(type: type, items: items) {
            if self.streamViewController.hasCellItems(for: .promotionalHeader) && !self.streamViewController.hasCellItems(for: .streamItems) {
                self.streamViewController.replacePlaceholder(type: .streamItems, items: [StreamCellItem(type: .streamLoading)])
            }

            completion()
        }
        updateInsets()
    }

    func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad(newItems: items)
    }

    func setPrimary(jsonable: JSONAble) {
        guard let pageHeader = jsonable as? PageHeader else { return }
        self.pageHeader = pageHeader

        if let trackingPostToken = pageHeader.postToken {
            let trackViews: ElloAPI = .promotionalViews(tokens: [trackingPostToken])
            ElloProvider.shared.request(trackViews).ignoreErrors()
        }

        updateInsets()
    }

    func set(category: Category) {
        self.category = category
        self.title = category.name
    }

    func set(subscribedCategories: [Category]) {
        self.subscribedCategories = subscribedCategories
        screen.categoriesLoaded = true

        var info: [CategoryCardListView.CategoryInfo] = []
        if hasSubscribedCategory {
            info.append(CategoryCardListView.CategoryInfo(title: InterfaceString.Discover.Subscribed, kind: .subscribed, imageURL: nil))
            screen.showSubscribed = true
        }
        else {
            screen.showSubscribed = false
        }

        info += subscribedCategories.map { (category: Category) -> CategoryCardListView.CategoryInfo in
            return CategoryCardListView.CategoryInfo(title: category.name, kind: .category, imageURL: category.tileURL)
        }

        let pullToRefreshView = streamViewController.pullToRefreshView
        pullToRefreshView?.isHidden = true
        screen.set(categoriesInfo: info) {
            pullToRefreshView?.isHidden = false
        }

        if case let .category(slug) = categorySelection,
            let selectedCategoryIndex = subscribedCategories.index(where: { $0.slug == slug })
        {
            screen.scrollToCategory(.category(selectedCategoryIndex))
            screen.selectCategory(.category(selectedCategoryIndex))
        }

        let screenSelection: CategoryScreen.Selection
        switch categorySelection {
        case .all:
            screenSelection = .all
        case .subscribed:
            screenSelection = .subscribed
        case let .category(slug):
            if let index = subscribedCategories.index(where: { $0.slug == slug }) {
                screenSelection = .category(index)
            }
            else {
                screenSelection = .all
            }
        }
        screen.selectCategory(screenSelection)

        updateInsets()
    }

    func primaryJSONAbleNotFound() {
        self.streamViewController.doneLoading()
    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }
}

extension CategoryViewController: CategoryScreenDelegate {
    func scrollToTop() {
        streamViewController.scrollToTop(animated: true)
    }

    func selectCategoryFor(slug: String) {
        guard let category = categoryFor(slug: slug) else {
            if subscribedCategories == nil {
                self.categorySelection = .category(slug)
            }
            return
        }
        select(category: category)
    }

    private func categoryFor(slug: String) -> Category? {
        return subscribedCategories?.find { $0.slug == slug }
    }

    func gridListToggled(sender: UIButton) {
        streamViewController.gridListToggled(sender)
    }

    func allCategoriesTapped() {
        selectAllCategories()
    }

    func seeAllCategoriesTapped() {
        guard let currentUser = currentUser else { return }

        let vc = ManageCategoriesViewController(currentUser: currentUser)
        vc.currentUser = currentUser
        navigationController?.pushViewController(vc, animated: true)
    }

    func subscribedCategoryTapped() {
        selectSubscribedCategory()
    }

    func categorySelected(index: Int) {
        guard
            let category = subscribedCategories?[index],
            category.id != self.category?.id
        else { return }

        select(category: category)
    }

    private func select(_ selection: Category.Selection) {
        switch selection {
        case .all:
            selectAllCategories()
        case .subscribed:
            selectSubscribedCategory()
        case let .category(slug):
            selectCategoryFor(slug: slug)
        }
    }

    private func selectAllCategories() {
        category = nil
        prevSelection = categorySelection
        categorySelection = .all
        title = InterfaceString.Discover.Title
        pageHeader = nil

        screen.scrollToCategory(.all)
        screen.selectCategory(.all)
        generator.reset(selection: categorySelection)
        streamViewController.streamKind = generator.streamKind
        loadCategory(reload: true, reloadCategories: false)

        trackScreenAppeared()
    }

    private func selectSubscribedCategory() {
        category = nil
        prevSelection = categorySelection
        categorySelection = .subscribed
        title = InterfaceString.Discover.Title
        pageHeader = nil

        screen.scrollToCategory(.subscribed)
        screen.selectCategory(.subscribed)
        generator.reset(selection: categorySelection)
        streamViewController.streamKind = generator.streamKind
        loadCategory(reload: true, reloadCategories: false)

        trackScreenAppeared()
    }

    private func select(category: Category) {
        Tracker.shared.categoryOpened(category.slug)

        self.category = category
        categorySelection = .category(category.slug)
        title = category.name

        if let index = subscribedCategories?.index(where: { $0.slug == category.slug }) {
            screen.scrollToCategory(.category(index))
            screen.selectCategory(.category(index))
        }
        generator.reset(selection: categorySelection)
        streamViewController.streamKind = generator.streamKind
        loadCategory(reload: true, reloadCategories: false)

        trackScreenAppeared()
    }

    func shareTapped(sender: UIView) {
        guard
            let shareURL = categorySelection.shareLink
        else { return }

        showShareActivity(sender: sender, url: shareURL)
    }

}

extension CategoryViewController: PromotionalHeaderResponder {
    func categorySubscribed(categoryId: String) {
        guard
            let currentUser = currentUser,
            !currentUser.subscribedTo(categoryId: categoryId)
        else { return }

        var newCategoryIds = currentUser.followedCategoryIds
        newCategoryIds.insert(categoryId)
        ElloHUD.showLoadingHudInView(streamViewController.view)
        ProfileService().update(categoryIds: newCategoryIds, onboarding: false)
            .always {
                ElloHUD.hideLoadingHudInView(self.streamViewController.view)
            }
            .then { _ -> Void in
                currentUser.followedCategoryIds = newCategoryIds
                self.appViewController?.currentUser = currentUser
            }
            .ignoreErrors()
    }
}
