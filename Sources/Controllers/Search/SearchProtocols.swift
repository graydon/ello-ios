////
///  SearchProtocols.swift
//

protocol SearchScreenDelegate: class {
    func backButtonTapped()
    func searchCanceled()
    func searchFieldCleared()
    func searchFieldChanged(_ text: String, isPostSearch: Bool)
    func searchShouldReset()
    func toggleChanged(_ text: String, isPostSearch: Bool)
    func gridListToggled(sender: UIButton)
    func findFriendsTapped()
}

protocol SearchScreenProtocol: StreamableScreenProtocol {
    var isGridView: Bool { get set }
    var delegate: SearchScreenDelegate? { get set }
    var showsFindFriends: Bool { get set }
    var topInsetView: UIView { get }
    func showNavBars(animated: Bool)
    func hideNavBars(animated: Bool)
    func searchFor(_ text: String)
    func updateInsets(bottom: CGFloat)
    func activateSearchField()
}
