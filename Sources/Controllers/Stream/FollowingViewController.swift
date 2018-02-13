////
///  FollowingViewController.swift
//

import SnapKit
import SwiftyUserDefaults


class FollowingViewController: StreamableViewController {
    override func trackerName() -> String? { return "Stream" }
    override func trackerProps() -> [String: Any]? {
        return ["kind": "Following"]
    }
    override func trackerStreamInfo() -> (String, String?)? {
        return ("following", nil)
    }

    var navigationBar = ElloNavigationBar()
    let newPostsButton = NewPostsButton()
    private var loggedPromptEventForThisSession = false
    private var reloadFollowingContentObserver: NotificationObserver?
    private var appBackgroundObserver: NotificationObserver?
    private var appForegroundObserver: NotificationObserver?
    private var newFollowingContentObserver: NotificationObserver?

    required init() {
        super.init(nibName: nil, bundle: nil)
        self.title = ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeNotificationObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupNavigationBar()
        setupNavigationItems(streamKind: .following)

        streamViewController.streamKind = .following
        ElloHUD.showLoadingHudInView(streamViewController.view)
        streamViewController.loadInitialPage()

        view.addSubview(newPostsButton)
        newPostsButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(view).offset(NewPostsButton.Size.top)
        }
        newPostsButton.addTarget(self, action: #selector(loadNewPosts), for: .touchUpInside)
        newPostsButton.alpha = 0

        addNotificationObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        addTemporaryNotificationObservers()
        if !loggedPromptEventForThisSession {
            Rate.sharedRate.logEvent()
            loggedPromptEventForThisSession = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeTemporaryNotificationObservers()
    }

    override func viewForStream() -> UIView {
        return view
    }

    override func showNavBars(animated: Bool) {
        super.showNavBars(animated: animated)
        positionNavBar(navigationBar, visible: true, animated: animated)
        updateInsets()
    }

    override func hideNavBars(animated: Bool) {
        super.hideNavBars(animated: animated)
        positionNavBar(navigationBar, visible: false, animated: animated)
        updateInsets()
    }

    @objc
    func loadNewPosts() {
        let scrollView = streamViewController.collectionView
        scrollView.setContentOffset(CGPoint(x: 0, y: -scrollView.contentInset.top), animated: true)
        postNotification(NewContentNotifications.reloadFollowingContent, value: ())

        hideNewPostsButton(animated: true)
    }

    override func streamWillPullToRefresh() {
        super.streamWillPullToRefresh()

        hideNewPostsButton(animated: true)
    }

    func hideNewPostsButton(animated: Bool) {
        animate(animated: animated) {
            self.newPostsButton.alpha = 0
        }
    }

}

private extension FollowingViewController {

    func updateInsets() {
        updateInsets(maxY: max(navigationBar.frame.maxY - 14, 0))
    }

    func setupNavigationBar() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: ElloNavigationBar.Size.largeHeight)
        navigationBar.sizeClass = .large
        navigationBar.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        view.addSubview(navigationBar)

        arrangeHomeScreenNavBar(type: .following, navigationBar: navigationBar)
    }

    func setupNavigationItems(streamKind: StreamKind) {
        navigationBar.leftItems = [.burger]
        navigationBar.rightItems = [.gridList(isGrid: streamKind.isGridView)]
    }

    func addTemporaryNotificationObservers() {
        reloadFollowingContentObserver = NotificationObserver(notification: NewContentNotifications.reloadFollowingContent) { [weak self] in
            guard let `self` = self else { return }

            ElloHUD.showLoadingHudInView(self.streamViewController.view)
            self.hideNewPostsButton(animated: true)
            self.streamViewController.loadInitialPage(reload: true)
        }
    }

    func removeTemporaryNotificationObservers() {
        reloadFollowingContentObserver?.removeObserver()
    }

    func addNotificationObservers() {
        newFollowingContentObserver = NotificationObserver(notification: NewContentNotifications.newFollowingContent) { [weak self] in
            guard let `self` = self else { return }

            animate {
                self.newPostsButton.alpha = 1
            }
        }

        appBackgroundObserver = NotificationObserver(notification: Application.Notifications.DidEnterBackground) { [weak self] _ in
            self?.loggedPromptEventForThisSession = false
        }
    }

    func removeNotificationObservers() {
        newFollowingContentObserver?.removeObserver()
        appBackgroundObserver?.removeObserver()
    }
}

extension FollowingViewController: HomeScreenNavBar {

    @objc
    func homeScreenScrollToTop() {
        streamViewController.collectionView.setContentOffset(.zero, animated: true)
    }

    @objc
    func homeScreenEditorialsTapped() {
        let responder: HomeResponder? = self.findResponder()
        responder?.showEditorialsViewController()
    }

    @objc
    func homeScreenArtistInvitesTapped() {
        let responder: HomeResponder? = self.findResponder()
        responder?.showArtistInvitesViewController()
    }

}
