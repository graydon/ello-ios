////
///  ElloLogoView.swift
//

import QuartzCore
import FLAnimatedImage


class ElloLogoView: UIView {

    enum Style {
        case normal
        case loading

        var size: CGSize {
            switch self {
            case .loading: return Size.loading
            default: return Size.natural
            }
        }
    }

    struct Size {
        static let natural = CGSize(width: 60, height: 60)
        static let loading = CGSize(width: 30, height: 30)
    }

    var isLogoAnimating: Bool { return _isAnimating }
    private var _isAnimating = false
    private let style: ElloLogoView.Style
    private let loadingLayer = LoadingGradientLayer()

    override var intrinsicContentSize: CGSize {
        return style.size
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.style = .normal
        super.init(coder: coder)
        privateInit()
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        privateInit()
    }

    override init(frame: CGRect) {
        self.style = .normal
        super.init(frame: frame)
        privateInit()
    }

    private func privateInit() {
        layer.addSublayer(loadingLayer)
        contentMode = .scaleAspectFit
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && _isAnimating {
            startAnimating()
        }
    }

    func startAnimating() {
        _isAnimating = true

        loadingLayer.startAnimating()
    }

    func stopAnimating() {
        _isAnimating = false

        loadingLayer.stopAnimating()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let loadingSize = intrinsicContentSize
        loadingLayer.cornerRadius = min(loadingSize.height, loadingSize.width) / 2
        loadingLayer.frame.size = loadingSize
        loadingLayer.frame.center = bounds.center
    }
}
