////
///  LoadingGradientLayer.swift
//

class LoadingGradientLayer: CAGradientLayer {
    let animation = CAKeyframeAnimation()

    override init(layer: Any) {
        super.init(layer: layer)
    }

    override init() {
        super.init()

        locations = [0, 1]
        colors = [
            UIColor(hex: 0xff0000).cgColor,
            UIColor(hex: 0xd200ff).cgColor,
        ]
        startPoint = CGPoint(x: 0, y: 0.5)
        endPoint = CGPoint(x: 1, y: 0.5)

        animation.keyPath = "colors"
        animation.values = [
            [UIColor(hex: 0xff0000).cgColor, UIColor(hex: 0xd200ff).cgColor],
            [UIColor(hex: 0xd200ff).cgColor, UIColor(hex: 0x0063ff).cgColor],
            [UIColor(hex: 0x0063ff).cgColor, UIColor(hex: 0x00ffc1).cgColor],
            [UIColor(hex: 0x00ffc1).cgColor, UIColor(hex: 0x0bff66).cgColor],
            [UIColor(hex: 0x0bff66).cgColor, UIColor(hex: 0x16ff00).cgColor],
            [UIColor(hex: 0x16ff00).cgColor, UIColor(hex: 0xf0ff00).cgColor],
            [UIColor(hex: 0xf0ff00).cgColor, UIColor(hex: 0xff0000).cgColor],
            [UIColor(hex: 0xff0000).cgColor, UIColor(hex: 0xd200ff).cgColor],
        ]
        animation.duration = 10
        animation.repeatCount = Float.infinity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        removeAnimation(forKey: "colors")
        add(animation, forKey: "colors")
    }

    func stopAnimating() {
        removeAnimation(forKey: "colors")
    }

}
