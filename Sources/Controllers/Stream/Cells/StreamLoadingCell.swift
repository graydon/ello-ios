////
///  StreamLoadingCell.swift
//

class StreamLoadingCell: CollectionViewCell {
    static let reuseIdentifier = "StreamLoadingCell"
    struct Size {
        static let height: CGFloat = 90
    }

    let elloLogo = ElloLogoView(style: .loading)

    override func arrange() {
        addSubview(elloLogo)

        elloLogo.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
    }

    override func style() {
        backgroundColor = .white
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}

protocol LoadingCell {
    func startAnimating()
    func stopAnimating()
}

extension StreamLoadingCell: LoadingCell {
    func startAnimating() {
        elloLogo.startAnimating()
    }

    func stopAnimating() {
        elloLogo.stopAnimating()
    }
}
