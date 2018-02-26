////
///  CategoryViewController.swift
//

final class CategoryViewController: StreamableViewController {
    override func trackerName() -> String? { return "Discover" }
    override func trackerProps() -> [String: Any]? {
        guard let slug = slug else { return nil }

        return ["category": slug]
    }
    override func trackerStreamInfo() -> (String, String?)? {
        if let streamId = category?.id {
            return ("category", streamId)
        }
        else if let slug = slug, DiscoverType.fromURL(slug) != nil {
            return (slug, nil)
        }
        else {
            return nil
        }
    }

    private var _mockScreen: CategoryScreenProtocol?
    var screen: CategoryScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return fetchScreen(_mockScreen) }
    }

    var category: Category?
    var slug: String?
    private var prevSlug: String?
    var allCategories: [Category]?
    var pageHeader: PageHeader?
    var generator: CategoryGenerator!
    var userDidScroll: Bool = false
    private let usage: Usage

    private var streamKind: StreamKind {
        if let slug = slug, let type = DiscoverType.fromURL(slug) {
            return .discover(type: type)
        }
        else if let slug = slug {
            return .category(slug: slug)
        }
        else {
            return .allCategories
        }
    }

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

    init(slug: String?, name: String? = nil, usage: Usage = .default) {
        self.usage = usage
        self.slug = slug
        super.init(nibName: nil, bundle: nil)
        self.title = name

        self.generator = CategoryGenerator(
            slug: slug,
            currentUser: currentUser,
            streamKind: streamKind,
            destination: self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        generator.currentUser = currentUser
    }

    override func loadView() {
        let screen = CategoryScreen(usage: usage)
        screen.navigationBar.title = ""
        screen.delegate = self

        self.view = screen
        viewContainer = screen.streamContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if slug.flatMap({ DiscoverType.fromURL($0) }) != nil {
            screen.setupNavBar(show: .onlyGridToggle, back: showBackButton, animated: false)
        }
        else if slug != nil {
            screen.setupNavBar(show: .all, back: showBackButton, animated: false)
        }
        else {
            screen.setupNavBar(show: .none, back: true, animated: false)
        }
        streamViewController.streamKind = streamKind
        screen.isGridView = streamKind.isGridView

        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.initialLoadClosure = { [weak self] in self?.loadCategory(reload: false) }
        streamViewController.reloadClosure = { [weak self] in self?.reloadCurrentCategory() }
        streamViewController.toggleClosure = { [weak self] isGridView in self?.toggleGrid(isGridView) }

        self.loadCategory(reload: false)
    }

    private func updateInsets() {
        updateInsets(navBar: screen.topInsetView)

        if !userDidScroll && screen.categoryCardsVisible {
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
        generator?.toggleGrid()
    }

    override func streamViewWillBeginDragging(scrollView: UIScrollView) {
        super.streamViewWillBeginDragging(scrollView: scrollView)
        userDidScroll = true
    }

    override func backButtonTapped() {
        if slug == nil {
            selectCategoryFor(slug: prevSlug ?? "featured")
        }
        else {
            super.backButtonTapped()
        }
    }
}

private extension CategoryViewController {

    func loadCategory(reload: Bool) {
        if reload {
            replacePlaceholder(type: .streamPosts, items: [StreamCellItem(type: .streamLoading)])
        }
        title = category?.name ?? slug.flatMap({ DiscoverType.fromURL($0) }).map({ $0.name }) ?? InterfaceString.Discover.Title

        pageHeader = nil
        generator?.load(reload: reload)

        streamViewController.isPagingEnabled = true
    }

    func reloadCurrentCategory() {
        pageHeader = nil
        generator?.load(reload: true)
    }
}

// MARK: CategoryViewController: StreamDestination
extension CategoryViewController: CategoryStreamDestination, StreamDestination {

    var isPagingEnabled: Bool {
        get { return streamViewController.isPagingEnabled }
        set { streamViewController.isPagingEnabled = newValue }
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping Block) {
        streamViewController.replacePlaceholder(type: type, items: items) {
            if self.streamViewController.hasCellItems(for: .promotionalHeader) && !self.streamViewController.hasCellItems(for: .streamPosts) {
                self.streamViewController.replacePlaceholder(type: .streamPosts, items: [StreamCellItem(type: .streamLoading)])
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
        streamViewController.doneLoading()
    }

    func set(category: Category) {
        self.category = category
        self.title = category.name
    }

    func set(categories allCategories: [Category]) {
        self.allCategories = allCategories

        let categories: [Category]
        if let streamKind = generator?.streamKind,
            case .allCategories = streamKind
        {
            categories = allCategories
        }
        else {
            categories = allCategories.filter { $0.level == .meta || $0.level == .primary }
        }

        let shouldAnimate = !screen.categoryCardsVisible
        let info = categories.map { (category: Category) -> CategoryCardListView.CategoryInfo in
            return CategoryCardListView.CategoryInfo(title: category.name, imageURL: category.tileURL)
        }

        let pullToRefreshView = streamViewController.pullToRefreshView
        pullToRefreshView?.isHidden = true
        screen.set(categoriesInfo: info, animated: shouldAnimate) {
            pullToRefreshView?.isHidden = false
        }

        let selectedCategoryIndex = categories.index { $0.slug == slug }
        if let selectedCategoryIndex = selectedCategoryIndex, shouldAnimate {
            screen.scrollToCategory(index: selectedCategoryIndex)
            screen.selectCategory(index: selectedCategoryIndex)
        }

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
            if allCategories == nil {
                self.slug = slug
            }
            return
        }
        select(category: category)
    }

    private func categoryFor(slug: String) -> Category? {
        return allCategories?.find { $0.slug == slug }
    }

    func gridListToggled(sender: UIButton) {
        streamViewController.gridListToggled(sender)
    }

    func allCategoriesTapped() {
        selectAllCategories()
    }

    func categorySelected(index: Int) {
        guard
            let category = allCategories?.safeValue(index),
            category.id != self.category?.id
        else { return }

        select(category: category)
    }

    private func selectAllCategories() {
        guard let allCategories = allCategories else { return }

        let streamKind = StreamKind.allCategories
        streamViewController.streamKind = streamKind
        streamViewController.isPagingEnabled = false
        generator?.reset(streamKind: streamKind, category: nil, pageHeader: nil)

        prevSlug = slug
        category = nil
        slug = nil
        title = InterfaceString.Discover.Title
        pageHeader = nil

        screen.setupNavBar(show: .none, back: true, animated: true)
        screen.scrollToCategory(index: -1)
        screen.selectCategory(index: -1)
        screen.categoryCardsVisible = false

        let sortedCategories = CategoryList(categories: allCategories).categories
        let categoryItems = allCategoryItems(categories: sortedCategories)
        replacePlaceholder(type: .promotionalHeader, items: [])
        replacePlaceholder(type: .streamPosts, items: categoryItems)

        trackScreenAppeared()
    }

    private func select(category: Category) {
        Tracker.shared.categoryOpened(category.slug)

        var kind: StreamKind?
        let showShare: Bool
        switch category.level {
        case .meta:
            showShare = false
            if let type = DiscoverType.fromURL(category.slug) {
                kind = .discover(type: type)
            }
        default:
            showShare = true
            kind = .category(slug: category.slug)
        }

        guard let streamKind = kind else { return }

        streamViewController.streamKind = streamKind
        screen.isGridView = streamKind.isGridView
        screen.setupNavBar(show: showShare ? .all : .onlyGridToggle, back: showBackButton, animated: true)
        screen.categoryCardsVisible = true
        generator?.reset(streamKind: streamKind, category: category, pageHeader: nil)
        self.category = category
        self.slug = category.slug
        self.title = category.name
        loadCategory(reload: true)

        if let index = allCategories?.index(where: { $0.slug == category.slug }) {
            screen.scrollToCategory(index: index)
            screen.selectCategory(index: index)
        }
        trackScreenAppeared()
    }

    func shareTapped(sender: UIView) {
        guard
            let category = category,
            let shareURL = URL(string: category.shareLink)
        else { return }

        showShareActivity(sender: sender, url: shareURL)
    }

}

// MARK: StreamViewDelegate
extension CategoryViewController {
    func allCategoryItems(categories: [Category]) -> [StreamCellItem] {
        let metaCategories = categories.filter { $0.isMeta }
        let cardCategories = categories.filter { !$0.isMeta }

        let metaCategoriesList = CategoryList(categories: metaCategories)
        let metaCategoriesItem = StreamCellItem(jsonable: metaCategoriesList, type: .categoryList)
        var items: [StreamCellItem] = [metaCategoriesItem]
        items += cardCategories.map { StreamCellItem(jsonable: $0, type: .categoryCard) }
        return items
    }
}
