////
///  ProfileTotalCountSizeCalculator.swift
//

import PromiseKit


struct ProfileTotalCountSizeCalculator {

    func calculate(_ item: StreamCellItem) -> Promise<CGFloat> {
        let (promise, resolve, _) = Promise<CGFloat>.pending()
        guard
            let user = item.jsonable as? User,
            user.hasProfileData,
            let count = user.totalViewsCount,
            count > 0
        else {
            resolve(0)
            return promise
        }

        resolve(ProfileTotalCountView.Size.height)
        return promise
    }
}
