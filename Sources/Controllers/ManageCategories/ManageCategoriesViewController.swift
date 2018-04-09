////
///  ManageCategoriesViewController.swift
//

class ManageCategoriesViewController: StreamableViewController {
    private var _mockScreen: ManageCategoriesScreenProtocol?
    var screen: ManageCategoriesScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return fetchScreen(_mockScreen) }
    }

    var generator: ManageCategoriesGenerator!
    var selectedIds: Set<String>?

    init(currentUser: User) {
        super.init(nibName: nil, bundle: nil)
        self.generator = ManageCategoriesGenerator(
            currentUser: currentUser,
            destination: self
        )
        self.currentUser = currentUser
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        generator.currentUser = currentUser
    }

    override func loadView() {
        let screen = ManageCategoriesScreen()
        screen.navigationBar.title = InterfaceString.Discover.Subscriptions
        screen.delegate = self

        view = screen
        viewContainer = screen.streamContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        streamViewController.streamKind = .manageCategories
        streamViewController.reloadClosure = { [weak self] in self?.generator?.load(reload: true) }

        ElloHUD.showLoadingHudInView(streamViewController.view)
        generator.load(reload: false)
    }

    private func updateInsets() {
        updateInsets(navBar: screen.navigationBar)
    }

    override func showNavBars(animated: Bool) {
        super.showNavBars(animated: animated)
        positionNavBar(screen.navigationBar, visible: true, withConstraint: screen.navigationBarTopConstraint, animated: animated)
        updateInsets()
    }

    override func hideNavBars(animated: Bool) {
        super.hideNavBars(animated: animated)
        positionNavBar(screen.navigationBar, visible: false, withConstraint: screen.navigationBarTopConstraint, animated: animated)
        updateInsets()
    }

    override func backButtonTapped() {
        guard hasPendingChanges() else {
            super.backButtonTapped()
            return
        }

        Tracker.shared.categoriesEdited()
        saveAndExit()
    }

    override func closeButtonTapped() {
        if hasPendingChanges() {
            let alertController = AlertViewController(message: InterfaceString.Settings.AbortChanges)

            let okCancelAction = AlertAction(style: .okCancel) { _ in
                super.backButtonTapped()
            }
            alertController.addAction(okCancelAction)

            self.present(alertController, animated: true, completion: nil)
        }
        else {
            super.backButtonTapped()
        }
    }

    private func hasPendingChanges() -> Bool {
        guard
            let currentUser = currentUser,
            let selectedIds = selectedIds
        else { return false }

        return selectedIds != currentUser.followedCategoryIds
    }

    private func saveAndExit() {
        guard let selectedIds = selectedIds else { return }

        view.isUserInteractionEnabled = false
        ElloHUD.showLoadingHudInView(self.view)

        ProfileService().update(categoryIds: selectedIds, onboarding: false)
            .done { _ in
                if let currentUser = self.currentUser {
                    currentUser.followedCategoryIds = selectedIds
                    self.appViewController?.currentUser = currentUser
                }
                super.backButtonTapped()
            }
            .catch { _ in
                self.view.isUserInteractionEnabled = true
            }
            .finally {
                ElloHUD.hideLoadingHudInView(self.view)
            }
    }
}

extension ManageCategoriesViewController: SelectedCategoryResponder {
    func categoriesSelectionChanged(selection: [Category]) {
        selectedIds = Set(selection.map { $0.id })
    }
}

extension ManageCategoriesViewController: StreamDestination {

    var isPagingEnabled: Bool {
        get { return streamViewController.isPagingEnabled }
        set { streamViewController.isPagingEnabled = newValue }
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping Block) {
        streamViewController.replacePlaceholder(type: type, items: items) {
            if type == .streamItems, let currentUser = self.currentUser {
                for (row, item) in items.enumerated() {
                    guard
                        let category = item.jsonable as? Category,
                        currentUser.subscribedTo(categoryId: category.id)
                    else { continue }

                    self.streamViewController.collectionView.selectItem(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: [])
                }
            }

            completion()
        }

        if type == .streamItems {
            streamViewController.doneLoading()
        }
    }

    func setPlaceholders(items: [StreamCellItem]) {
        streamViewController.clearForInitialLoad(newItems: items)
    }

    func setPrimary(jsonable: JSONAble) {
    }

    func primaryJSONAbleNotFound() {
        self.streamViewController.doneLoading()
    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        streamViewController.responseConfig = responseConfig
    }
}

extension ManageCategoriesViewController: ManageCategoriesScreenDelegate {
}
