////
///  StreamSelectionCellSpec.swift
//

@testable import Ello
import Quick
import Nimble


class StreamSelectionCellSpec: QuickSpec {

    class FakeStreamSelectionCellResponder: UIView, StreamSelectionCellResponder {
        var categoryTapped = false
        var slug: String?
        var name: String?

        func categoryListCellTapped(slug: String, name: String) {
            categoryTapped = true
            self.slug = slug
            self.name = name
        }
    }

    override func spec() {
        describe("StreamSelectionCell") {
            var subject: StreamSelectionCell!
            var responder: FakeStreamSelectionCellResponder!

            beforeEach {
                responder = FakeStreamSelectionCellResponder()
                let frame = CGRect(origin: .zero, size: CGSize(width: 320, height: StreamSelectionCell.Size.height))
                subject = StreamSelectionCell(frame: frame)
                showView(subject, container: responder)
            }

            describe("actions") {
                it("sends action when tapping on a category") {
                    subject.categoriesInfo = [
                        (title: "Featured", slug: "featured"),
                        (title: "Trending", slug: "trending"),
                        (title: "Recent", slug: "recent"),
                    ]
                    let categoryButton: UIButton? = subview(of: subject, thatMatches: { button in
                        button.currentAttributedTitle?.string == "Featured"
                    })
                    categoryButton?.sendActions(for: .touchUpInside)
                    expect(responder.categoryTapped) == true
                    expect(responder.slug) == "featured"
                }
            }

            it("displays categories") {
                subject.categoriesInfo = [
                    (title: "Featured", slug: "featured"),
                    (title: "Trending", slug: "trending"),
                    (title: "Recent", slug: "recent"),
                ]
                expectValidSnapshot(subject)
            }
        }
    }
}
