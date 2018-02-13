////
///  CategoryProtocols.swift
//

protocol CategoryScreenDelegate: class {
    func scrollToTop()
    func backButtonTapped()
    func shareTapped(sender: UIView)
    func gridListToggled(sender: UIButton)
    func allCategoriesTapped()
    func categorySelected(index: Int)
    func searchButtonTapped()
}

protocol CategoryScreenProtocol: StreamableScreenProtocol {
    var topInsetView: UIView { get }
    var categoryCardsVisible: Bool { get set }
    var isGridView: Bool { get set }
    func set(categoriesInfo: [CategoryCardListView.CategoryInfo], animated: Bool, completion: @escaping Block)
    func toggleCategoriesList(navBarVisible: Bool, animated: Bool)
    func scrollToCategory(index: Int)
    func selectCategory(index: Int)
    func setupNavBar(show: CategoryScreen.NavBarItems, back: Bool, animated: Bool)
}
