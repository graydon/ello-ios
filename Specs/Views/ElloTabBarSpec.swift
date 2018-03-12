////
///  ElloTabBarSpec.swift
//

@testable import Ello
import Quick
import Nimble


class ElloTabBarSpec: QuickSpec {
    override func spec() {
        describe("ElloTabBar") {
            var subject: ElloTabBar!
            var redDot: UIView!
            let portraitSize = CGSize(width: 320, height: 49)
            let landscapeSize = CGSize(width: 1024, height: 49)

            beforeEach {
                subject = ElloTabBar()
                subject.tabs = [
                    .home,
                    .discover,
                    .omnibar,
                    .notifications,
                    .profile,
                ]

                redDot = subject.addRedDotFor(tab: ElloTab.notifications)
                redDot.isVisible = true
            }

            context("red dot position") {
                context("portait") {
                    it("should be in the correct location") {
                        expectValidSnapshot(subject, device: .custom(portraitSize))
                    }
                }
                context("landscape") {
                    it("should be in the correct location") {
                        expectValidSnapshot(subject, device: .custom(landscapeSize))
                    }
                }
            }
        }
    }
}
