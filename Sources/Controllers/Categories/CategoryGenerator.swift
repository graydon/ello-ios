////
///  CategoryGenerator.swift
//

protocol CategoryStreamDestination: StreamDestination {
    func set(categories: [Category])
    func set(category: Category)
}

final class CategoryGenerator: StreamGenerator {

    var currentUser: User?
    var streamKind: StreamKind
    weak private var categoryStreamDestination: CategoryStreamDestination?
    weak var destination: StreamDestination? {
        get { return categoryStreamDestination }
        set {
            if !(newValue is CategoryStreamDestination) { fatalError("CategoryGenerator.destination must conform to CategoryStreamDestination") }
            categoryStreamDestination = newValue as? CategoryStreamDestination
        }
    }

    private var category: Category?
    private var categories: [Category]?
    private var slug: String?
    private var pageHeader: PageHeader?
    private var posts: [Post]?
    private var localToken: String = ""
    private var loadingToken = LoadingToken()

    private let queue = OperationQueue()

    init(slug: String?, currentUser: User?, streamKind: StreamKind, destination: StreamDestination) {
        self.slug = slug
        self.currentUser = currentUser
        self.streamKind = streamKind
        self.destination = destination
    }

    func headerItems() -> [StreamCellItem] {
        guard let pageHeader = pageHeader else { return [] }

        return [StreamCellItem(jsonable: pageHeader, type: .promotionalHeader)]
    }

    func reset(streamKind: StreamKind, category: Category?, pageHeader: PageHeader?) {
        self.streamKind = streamKind
        self.category = category
        self.slug = category?.slug
        self.pageHeader = nil
    }

    func load(reload: Bool = false) {
        if reload {
            pageHeader = nil
        }

        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        localToken = loadingToken.resetInitialPageLoadingToken()
        if reload {
            category = nil
            categories = nil
            pageHeader = nil
            posts = nil
        }
        else {
            setPlaceHolders()
        }

        if let slug = slug {
            loadCategory(slug: slug)
        }
        loadPageHeader(doneOperation)

        loadCategories()
        loadCategoryPosts(doneOperation, reload: reload)
    }

    func toggleGrid() {
        guard let posts = posts else { return }
        destination?.replacePlaceholder(type: .streamPosts, items: parse(jsonables: posts))
    }

}

private extension CategoryGenerator {

    func setPlaceHolders() {
        destination?.setPlaceholders(items: [
            StreamCellItem(type: .placeholder, placeholderType: .promotionalHeader),
            StreamCellItem(type: .placeholder, placeholderType: .streamPosts)
        ])
    }

    func loadCategory(slug: String) {
        CategoryService().loadCategory(slug)
            .then { category -> Void in
                guard self.loadingToken.isValidInitialPageLoadingToken(self.localToken) else { return }

                self.category = category
                self.categoryStreamDestination?.set(category: category)
            }
            .ignoreErrors()
    }

    func loadPageHeader(_ doneOperation: AsyncOperation) {
        let kind: API.PageHeaderKind
        if let slug = category?.slug ?? slug {
            kind = .category(slug)
        }
        else {
            kind = .generic
        }

        API().pageHeaders(kind: kind)
            .execute()
            .then { pageHeaders -> Void in
                guard self.loadingToken.isValidInitialPageLoadingToken(self.localToken) else { return }

                if let pageHeader = pageHeaders.randomItem() {
                    self.pageHeader = pageHeader
                    self.destination?.setPrimary(jsonable: pageHeader)
                }
                else {
                    self.destination?.primaryJSONAbleNotFound()
                }

                self.destination?.replacePlaceholder(type: .promotionalHeader, items: self.headerItems())
            }
            .catch { _ in
                self.destination?.primaryJSONAbleNotFound()
                self.queue.cancelAllOperations()
            }
            .always {
                doneOperation.run()
            }
    }

    func loadCategories() {
        API().subscribedCategories()
            .then { categories -> Void in
                self.categories = categories
                self.categoryStreamDestination?.set(categories: categories)
            }
            .ignoreErrors()
    }

    func loadCategoryPosts(_ doneOperation: AsyncOperation, reload: Bool) {
        let endpoint: ElloAPI
        if let discoverType = slug.flatMap({ DiscoverType.fromURL($0) }) {
            endpoint = .discover(type: discoverType)
        }
        else if let slug = slug {
            endpoint = .categoryPosts(slug: slug)
        }
        else {
            return
        }

        let displayPostsOperation = AsyncOperation()
        displayPostsOperation.addDependency(doneOperation)
        queue.addOperation(displayPostsOperation)

        StreamService().loadStream(
            endpoint: endpoint,
            streamKind: streamKind
            )
            .then { response -> Void in
                guard self.loadingToken.isValidInitialPageLoadingToken(self.localToken) else { return }

                switch response {
                case let .jsonables(jsonables, responseConfig):
                    self.destination?.setPagingConfig(responseConfig: responseConfig)
                    self.posts = jsonables as? [Post]
                    let items = self.parse(jsonables: jsonables)
                    displayPostsOperation.run {
                        inForeground {
                            if items.count == 0 {
                                let noItems = [StreamCellItem(type: .emptyStream(height: 182))]
                                self.destination?.replacePlaceholder(type: .streamPosts, items: noItems)
                                self.destination?.isPagingEnabled = false
                                self.destination?.replacePlaceholder(type: .promotionalHeader, items: self.headerItems())
                            }
                            else {
                                self.destination?.replacePlaceholder(type: .streamPosts, items: items) {
                                    self.destination?.isPagingEnabled = true
                                }
                            }
                        }
                    }
                case .empty:
                    let noContentItem = StreamCellItem(type: .emptyStream(height: 282))
                    self.destination?.replacePlaceholder(type: .streamPosts, items: [noContentItem])
                    self.destination?.isPagingEnabled = false
                    self.destination?.primaryJSONAbleNotFound()
                    self.queue.cancelAllOperations()
                }
            }
            .catch { _ in
                self.destination?.primaryJSONAbleNotFound()
                self.queue.cancelAllOperations()
            }
    }
}
