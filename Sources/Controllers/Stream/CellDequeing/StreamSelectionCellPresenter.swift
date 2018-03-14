////
///  StreamSelectionCellPresenter.swift
//

class StreamSelectionCellPresenter {
    static func configure(
        _ cell: UICollectionViewCell,
        streamCellItem: StreamCellItem,
        streamKind: StreamKind,
        indexPath: IndexPath,
        currentUser: User?)
    {
        guard
            let cell = cell as? StreamSelectionCell,
            case let .category(selection, stream) = streamKind
        else { return }

        switch selection {
        case .all:
            cell.streams = [.featured, .trending, .recent]
        default:
            cell.streams = [.featured, .trending]
        }
        cell.selectedStream = stream
    }
}
