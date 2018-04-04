////
///  ProfileTotalCountSizeCalculator.swift
//

import PromiseKit


struct ProfileTotalCountSizeCalculator {

    func calculate(_ item: StreamCellItem) -> Guarantee<CGFloat> {
        let (promise, fulfill) = Guarantee<CGFloat>.pending()
        guard
            let user = item.jsonable as? User,
            user.hasProfileData,
            let count = user.totalViewsCount,
            count > 0
        else {
            fulfill(0)
            return promise
        }

        fulfill(ProfileTotalCountView.Size.height)
        return promise
    }
}
