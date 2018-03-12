////
///  DrawerCellPresenter.swift
//

struct DrawerCellPresenter {

    static func configure(_ cell: DrawerCell, item: DrawerItem, isLast: Bool) {
        var isLineVisible = !isLast
        switch item.type {
        case .version:
            cell.style = .version
        case .spacer:
            cell.style = .default
            isLineVisible = false
        default:
            cell.style = .default
        }
        cell.isLineVisible = isLineVisible

        cell.title = item.title
        cell.logo = item.logo
    }
}
