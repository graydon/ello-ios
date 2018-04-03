////
///  ElloLogoView.swift
//

import QuartzCore
import FLAnimatedImage


class ElloLogoView: UIImageView {

    enum Style {
        case normal
        case grey
        case loading

        var size: CGSize {
            switch self {
            case .loading: return Size.loading
            default: return Size.natural
            }
        }

        var image: UIImage {
            switch self {
            case .normal, .loading: return InterfaceImage.elloLogo.normalImage
            case .grey: return InterfaceImage.elloLogoGrey.normalImage
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
        image = style.image
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

        self.layer.removeAnimation(forKey: "logo-spin")
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        let angle = layer.value(forKeyPath: "transform.rotation.z") as! Double
        rotate.fromValue = angle
        rotate.toValue = angle + 2 * Double.pi
        rotate.duration = 0.35
        rotate.repeatCount = 1_000_000
        self.layer.add(rotate, forKey: "logo-spin")
    }

    func stopAnimating() {
        _isAnimating = false

        self.layer.removeAllAnimations()

        let endAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        if let layer = self.layer.presentation() {
            let angle = layer.value(forKeyPath: "transform.rotation.z") as! NSNumber
            endAnimation.fromValue = angle.floatValue
            endAnimation.toValue = 0
            endAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            endAnimation.duration = 0.25
        }
        self.layer.add(endAnimation, forKey: "logo-spin")
    }

}
