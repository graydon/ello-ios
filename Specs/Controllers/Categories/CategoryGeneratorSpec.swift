////
///  CategoryGeneratorSpec.swift
//

@testable import Ello
import Quick
import Nimble

class CategoryGeneratorSpec: QuickSpec {
    override func spec() {
        describe("CategoryGenerator") {
            var destination: CategoryDestination!
            var currentUser: User!
            var streamKind: StreamKind!
            var category: Ello.Category!
            var subject: CategoryGenerator!

            beforeEach {
                destination = CategoryDestination()
                currentUser = User.stub(["id": "42"])
                streamKind = .category(slug: "recommended")
            }

            beforeEach {
                category = Ello.Category.stub(["level": "meta", "slug": "recommended"])
                subject = CategoryGenerator(
                    slug: category.slug,
                    currentUser: currentUser,
                    streamKind: streamKind,
                    destination: destination
                )
            }

            describe("load()") {

                it("sets 2 placeholders") {
                    subject.load()
                    expect(destination.placeholderItems.count) == 2
                }

                it("replaces only CatgoryHeader and CategoryPosts") {
                    subject.load()
                    expect(destination.headerItems.count) > 0
                    expect(destination.postItems.count) > 0
                    expect(destination.otherPlaceHolderLoaded) == false
                }

                it("sets the primary jsonable") {
                    subject.load()
                    expect(destination.pageHeader).toNot(beNil())
                }

                it("sets the categories") {
                    subject.load()
                    expect(destination.categories.count) > 0
                }

                it("sets the config response") {
                    subject.load()
                    expect(destination.responseConfig).toNot(beNil())
                }
            }
        }
    }
}

class CategoryDestination: CategoryStreamDestination {

    var placeholderItems: [StreamCellItem] = []
    var headerItems: [StreamCellItem] = []
    var postItems: [StreamCellItem] = []
    var otherPlaceHolderLoaded = false
    var categories: [Ello.Category] = []
    var pageHeader: PageHeader?
    var responseConfig: ResponseConfig?
    var isPagingEnabled: Bool = false

    func setPlaceholders(items: [StreamCellItem]) {
        placeholderItems = items
    }

    func replacePlaceholder(type: StreamCellType.PlaceholderType, items: [StreamCellItem], completion: @escaping Block) {
        switch type {
        case .promotionalHeader:
            headerItems = items
        case .streamItems:
            postItems = items
        default:
            otherPlaceHolderLoaded = true
        }
    }

    func setPrimary(jsonable: JSONAble) {
        self.pageHeader = jsonable as? PageHeader
    }

    func set(categories: [Ello.Category]) {
        self.categories = categories
    }

    func primaryJSONAbleNotFound() {
    }

    func setPagingConfig(responseConfig: ResponseConfig) {
        self.responseConfig = responseConfig
    }
}
