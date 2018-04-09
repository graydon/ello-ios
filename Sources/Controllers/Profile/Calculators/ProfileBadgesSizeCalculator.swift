////
///  ProfileBadgesSizeCalculator.swift
//

import PromiseKit


struct ProfileBadgesSizeCalculator {

    func calculate(_ item: StreamCellItem) -> Guarantee<CGFloat> {
        let (promise, fulfill) = Guarantee<CGFloat>.pending()
        guard
            let user = item.jsonable as? User,
            user.badges.count > 0
        else {
            fulfill(0)
            return promise
        }

        fulfill(ProfileBadgesView.Size.height)
        return promise
    }
}
