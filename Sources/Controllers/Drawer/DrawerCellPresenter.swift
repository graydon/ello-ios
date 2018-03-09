////
///  DrawerCellPresenter.swift
//

struct DrawerCellPresenter {

    static func configure(_ cell: DrawerCell, item: DrawerItem, isLast: Bool) {
        switch item.type {
        case .version:
            cell.style == .version
        default:
            cell.style = .default
        }

        cell.title = item.title
        cell.logo = item.logo
        cell.isLineVisible = !isLast
    }
}
