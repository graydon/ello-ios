////
///  CategoryViewControllerSpec.swift
//

@testable import Ello
import Quick
import Nimble


class CategoryViewControllerSpec: QuickSpec {
    class MockCategoryScreen: CategoryScreenProtocol {
        let topInsetView = UIView()
        let streamContainer = UIView()
        var isGridView = true
        var navigationBarTopConstraint: NSLayoutConstraint!
        let navigationBar = ElloNavigationBar()
        var categoryTitles: [String] = []
        var scrollTo: Int?
        var select: Int?
        var showShare: CategoryScreen.NavBarItems = .all
        var showBack = false

        func set(categoriesInfo: [CategoryCardListView.CategoryInfo], completion: @escaping Block) {
            categoryTitles = categoriesInfo.map { $0.title }
        }
        func toggleCategoriesList(navBarVisible: Bool, animated: Bool) {}
        func scrollToCategory(index: Int) {
            scrollTo = index
        }

        func selectCategory(index: Int) {
            select = index
        }

        func viewForStream() -> UIView {
            return streamContainer
        }

        func setupNavBar(show: CategoryScreen.NavBarItems, back backVisible: Bool, animated: Bool) {
            self.showShare = show
            self.showBack = backVisible
        }
    }

    override func spec() {
        describe("CategoryViewController") {
            let currentUser: User = stub([:])
            var subject: CategoryViewController!
            var screen: MockCategoryScreen!

            beforeEach {
                let category: Ello.Category = Ello.Category.stub([:])
                subject = CategoryViewController(currentUser: currentUser, slug: category.slug)
                screen = MockCategoryScreen()
                subject.screen = screen
                showController(subject)
            }

            it("has a nice looking nav bar") {
                expectValidSnapshot(subject, device: .phone6_Portrait)
            }

            it("shows the back button when necessary") {
                let category: Ello.Category = Ello.Category.stub([:])
                subject = CategoryViewController(currentUser: currentUser, slug: category.slug)
                screen = MockCategoryScreen()
                subject.screen = screen

                let nav = UINavigationController(rootViewController: UIViewController())
                nav.pushViewController(subject, animated: false)
                showController(nav)
                expect(screen.showBack) == true
            }

            it("restores the previous category") {
                let slug = subject.allCategories!.first!.slug
                subject.slug = slug
                subject.allCategoriesTapped()
                expect(subject.slug).to(beNil())
                expect(screen.showBack) == true
                subject.backButtonTapped()
                expect(subject.slug) == slug
                expect(screen.showBack) == false
            }

            context("setCategories(_:)") {
                it("accepts meta categories") {
                    subject.set(categories: [
                        Category.stub(["name": "Art"])
                        ])
                    expect(screen.categoryTitles) == ["Art"]
                }
            }
        }
    }
}
