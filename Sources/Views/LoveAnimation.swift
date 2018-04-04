////
///  LoveAnimation.swift
//

class LoveAnimation {
    static func perform(inWindow window: UIWindow, at location: CGPoint) {
        let fullDuration: TimeInterval = 0.4
        let halfDuration: TimeInterval = fullDuration / 2

        let imageView = UIImageView(image: InterfaceImage.giantHeart.normalImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = window.bounds
        imageView.center = location
        imageView.alpha = 0
        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        // fade in, then fade out
        animate(duration: halfDuration) {
            imageView.alpha = 0.5
        }.done {
            animate(duration: halfDuration) {
                imageView.alpha = 0
            }
        }

        // grow throughout the animation
        animate(duration: fullDuration) {
            imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }.done {
            imageView.removeFromSuperview()
        }
        window.addSubview(imageView)
    }
}
