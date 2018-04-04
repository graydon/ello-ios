////
///  ElloPullToRefreshView.swift
//

import SSPullToRefresh
import QuartzCore

class ElloPullToRefreshView: UIView, SSPullToRefreshContentView {

    private var pullProgress: CGFloat = 0
    private var loading = false
    private let toValue = (360.0 * Double.pi) / 180.0

    lazy var elloLogo: ElloLogoView = {
        let logo = ElloLogoView(style: .loading)
        logo.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        logo.bounds = CGRect(x: 0, y: 0, width: 30, height: 30)
        return logo
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.sharedInit()
    }

    private func sharedInit() {
        self.addSubview(elloLogo)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        elloLogo.center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
    }

// MARK: SSPullToRefreshContentView

    func setState(_ state: SSPullToRefreshViewState, with view: SSPullToRefreshView!) {
        switch state {
        case .loading:
            loading = true
            elloLogo.startAnimating()
        case .closing:
            loading = false
            elloLogo.stopAnimating()
        default:
            loading = false
        }
    }

    func setPullProgress(_ pullProgress: CGFloat) {
        self.pullProgress = pullProgress
        let alpha = max(0, (pullProgress- 0.5) * 2)
        elloLogo.alpha = alpa
    }

}
