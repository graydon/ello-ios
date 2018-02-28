////
///  CategoryGenerator.swift
//

import PromiseKit


protocol CategoryStreamDestination: StreamDestination {
    func set(subscribedCategories: [Category])
    func set(allCategories: [Category])
}

final class CategoryGenerator: StreamGenerator {
    var streamKind: StreamKind = .unknown
    var currentUser: User?
    weak private var categoryStreamDestination: CategoryStreamDestination?
    weak var destination: StreamDestination? {
        get { return categoryStreamDestination }
        set {
            if !(newValue is CategoryStreamDestination) { fatalError("CategoryGenerator.destination must conform to CategoryStreamDestination") }
            categoryStreamDestination = newValue as? CategoryStreamDestination
        }
    }

    private var subscribedCategories: [Category]?
    private var categorySelection: Category.Selection
    private var pageHeader: PageHeader?
    private var posts: [Post]?
    private var localToken: String = ""
    private var loadingToken = LoadingToken()
    private let queue = OperationQueue()

    private var nextPageRequest: GraphQLRequest<(PageConfig, [Post])>?
    private var nextRequestGenerator: ((String) -> GraphQLRequest<(PageConfig, [Post])>)?

    init(selection: Category.Selection, currentUser: User?, destination: StreamDestination) {
        self.streamKind = .category(selection)
        self.categorySelection = selection
        self.currentUser = currentUser
        self.destination = destination
    }

    func headerItems() -> [StreamCellItem] {
        guard let pageHeader = pageHeader else { return [] }

        return [StreamCellItem(jsonable: pageHeader, type: .promotionalHeader)]
    }

    func reset(category: Category?, selection: Category.Selection) {
        self.categorySelection = selection
        self.pageHeader = nil
        self.streamKind = .category(selection)
    }

    func load(reload: Bool = false) {
        let doneOperation = AsyncOperation()
        queue.addOperation(doneOperation)

        localToken = loadingToken.resetInitialPageLoadingToken()
        if reload {
            subscribedCategories = nil
            pageHeader = nil
            posts = nil
            self.destination?.replacePlaceholder(type: .promotionalHeader, items: [])
            self.destination?.replacePlaceholder(type: .streamItems, items: [])
        }
        else {
            setPlaceHolders()
        }

        loadPageHeader(doneOperation)
        loadSubscribedCategories()
        loadCategoryPosts(doneOperation, reload: reload)
    }

    func toggleGrid() {
        guard let posts = posts else { return }
        destination?.replacePlaceholder(type: .streamItems, items: parse(jsonables: posts))
    }

    func loadNextPage() -> Promise<[JSONAble]>? {
        guard
            let nextPageRequest = nextPageRequest
        else { return nil }

        return nextPageRequest
            .execute()
            .then { pageConfig, posts -> [JSONAble] in
                self.setNextPageConfig(pageConfig)
                if posts.count == 0 {
                    self.destination?.isPagingEnabled = false
                }
                return posts
            }
            .catch { error in
                let errorConfig = PageConfig(next: nil, isLastPage: true)
                self.destination?.setPagingConfig(responseConfig: ResponseConfig(pageConfig: errorConfig))
                self.destination?.isPagingEnabled = false
            }
    }
}

extension CategoryGenerator {

    private func setPlaceHolders() {
        destination?.setPlaceholders(items: [
            StreamCellItem(type: .placeholder, placeholderType: .promotionalHeader),
            StreamCellItem(type: .placeholder, placeholderType: .streamItems)
        ])
    }

    private func loadPageHeader(_ doneOperation: AsyncOperation) {
        let kind: API.PageHeaderKind
        if case let .category(slug) = categorySelection {
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

    private func loadSubscribedCategories() {
        API().subscribedCategories()
            .execute()
            .then { subscribedCategories -> Void in
                self.subscribedCategories = subscribedCategories
                self.categoryStreamDestination?.set(subscribedCategories: subscribedCategories)
            }
            .ignoreErrors()
    }

    private func loadCategoryPosts(_ doneOperation: AsyncOperation, reload: Bool) {
        let request: GraphQLRequest<(PageConfig, [Post])>
        switch categorySelection {
        case .all:
            request = API().globalPostStream()
            nextRequestGenerator = { next in return API().globalPostStream(before: next) }
        case .subscribed:
            request = API().subscribedPostStream()
            nextRequestGenerator = { next in return API().subscribedPostStream(before: next) }
        case let .category(slug):
            request = API().categoryPostStream(categorySlug: slug)
            nextRequestGenerator = { next in return API().categoryPostStream(categorySlug: slug, before: next) }
        }

        let displayPostsOperation = AsyncOperation()
        displayPostsOperation.addDependency(doneOperation)
        queue.addOperation(displayPostsOperation)

        request.execute()
            .then { pageConfig, posts -> Void in
                guard self.loadingToken.isValidInitialPageLoadingToken(self.localToken) else { return }

                self.setNextPageConfig(pageConfig)

                self.posts = posts
                var items = self.parse(jsonables: posts)
                let isPagingEnabled = items.count > 0
                if items.count == 0 {
                    items = [StreamCellItem(type: .emptyStream(height: 182))]
                }

                displayPostsOperation.run { inForeground {
                    self.destination?.replacePlaceholder(type: .streamItems, items: items) {
                        self.destination?.isPagingEnabled = isPagingEnabled
                    }
                } }
            }
            .catch { _ in
                self.destination?.primaryJSONAbleNotFound()
                self.queue.cancelAllOperations()
            }
    }

    private func setNextPageConfig(_ pageConfig: PageConfig) {
        self.destination?.setPagingConfig(responseConfig: ResponseConfig(pageConfig: pageConfig))

        if let next = pageConfig.next, let nextRequestGenerator = nextRequestGenerator {
            self.nextPageRequest = nextRequestGenerator(next)
        }
        else {
            self.nextPageRequest = nil
            self.nextRequestGenerator = nil
        }
    }
}
