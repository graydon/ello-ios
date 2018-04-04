////
///  ProfileStatsSizeCalculatorSpec.swift
//

@testable import Ello
import Quick
import Nimble


class ProfileStatsSizeCalculatorSpec: QuickSpec {
    override func spec() {
        describe("ProfileStatsSizeCalculator") {
            it("always returns the right number") {
                let user: User = stub([:])
                let calc = ProfileStatsSizeCalculator()
                var height: CGFloat!
                calc.calculate(StreamCellItem(jsonable: user, type: .streamHeader))
                    .done { h in height = h }
                    .catch { _ in }
                expect(height) == 60
            }
        }
    }
}
