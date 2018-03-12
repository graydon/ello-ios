////
///  CommentsIcon.swift
//

class CommentsIcon: BasicIcon {
    private let commentTailView: UIView

    init(isDark: Bool) {
        let tailStyle: InterfaceImage.Style
        let selectedStyle: InterfaceImage.Style
        if isDark {
            tailStyle = .white
            selectedStyle = .white
        }
        else {
            tailStyle = .normal
            selectedStyle = .selected
        }

        let icon = UIImageView(image: InterfaceImage.bubbleBody.normalImage)
        let iconSelected = UIImageView(image: InterfaceImage.bubbleBody.image(selectedStyle))

        commentTailView = UIImageView(image: InterfaceImage.bubbleTail.image(tailStyle))
        super.init(normalIconView: icon, selectedIconView: iconSelected)
        addSubview(commentTailView)
        commentTailView.isHidden = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateIcon(selected: Bool, enabled: Bool) {
        super.updateIcon(selected: selected, enabled: enabled)
        commentTailView.isVisible = selected
    }
}

extension CommentsIcon {
    func animate() {
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.values = [0, 8.9, 9.9, 9.9, 0.1, 0, 0]
        animation.keyTimes = [0, 0.25, 0.45, 0.55, 0.75, 0.95, 0]
        animation.duration = 0.6
        animation.repeatCount = Float.infinity
        animation.isAdditive = true
        commentTailView.layer.add(animation, forKey: "comments")
    }

    func finishAnimation() {
        commentTailView.layer.removeAnimation(forKey: "comments")
    }
}
