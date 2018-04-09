////
///  ProfileLocationSizeCalculator.swift
//

import PromiseKit


struct ProfileLocationSizeCalculator {

    func calculate(_ item: StreamCellItem, maxWidth: CGFloat) -> Guarantee<CGFloat> {
        let (promise, fulfill) = Guarantee<CGFloat>.pending()
        guard
            let user = item.jsonable as? User,
            let location = user.location, !location.isEmpty
        else {
            fulfill(0)
            return promise
        }

        fulfill(ProfileLocationView.Size.height)
        return promise
    }
}
