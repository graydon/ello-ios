////
///  ProfileNamesSizeCalculator.swift
//

import PromiseKit


struct ProfileNamesSizeCalculator {

    func calculate(_ item: StreamCellItem, maxWidth: CGFloat) -> Guarantee<CGFloat> {
        let (promise, fulfill) = Guarantee<CGFloat>.pending()
        guard
            let user = item.jsonable as? User
        else {
            fulfill(0)
            return promise
        }

        let nameFont = ProfileNamesView.nameFont
        let usernameFont = ProfileNamesView.usernameFont

        let viewWidth = maxWidth - ProfileNamesView.Size.outerMargins.sides
        let maxSize = CGSize(width: viewWidth, height: CGFloat.greatestFiniteMagnitude)

        let nameSize: CGSize
        if user.name.isEmpty {
            nameSize = .zero
        }
        else {
            nameSize = user.name.boundingRect(
                with: maxSize, options: [],
                attributes: [
                    .font: nameFont,
                ], context: nil).size.integral
        }

        let usernameSize = user.atName.boundingRect(
            with: maxSize, options: [],
            attributes: [
                .font: usernameFont,
            ], context: nil).size.integral

        let (height, _) = ProfileNamesView.preferredHeight(nameSize: nameSize, usernameSize: usernameSize, maxWidth: maxWidth)
        let totalHeight = height + ProfileNamesView.Size.outerMargins.tops
        fulfill(totalHeight)
        return promise
    }
}
