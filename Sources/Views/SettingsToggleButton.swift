////
///  SettingsToggleButton.swift
//

class SettingsToggleButton: StyledButton {
    override var intrinsicContentSize: CGSize {
        guard title == InterfaceString.Yes || title == InterfaceString.No else {
            var superSize = super.intrinsicContentSize
            if superSize.width != UIViewNoIntrinsicMetric {
                superSize.width += 20
            }
            return superSize
        }
        return CGSize(width: 50, height: 30)
    }

    override func setTitle(_ title: String?, for state: UIControlState) {
        super.setTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }

    convenience init() {
        self.init(frame: .zero)
        self.setTitle(InterfaceString.Yes, for: .selected)
        self.setTitle(InterfaceString.No, for: .normal)
        self.style = StyledButton.Style(
            backgroundColor: .greyA, selectedBackgroundColor: .greenD1,
            titleColor: .white, selectedTitleColor: .white,
            cornerRadius: .pill
            )
    }

    override func updateStyle() {
        super.updateStyle()
        self.alpha = isEnabled ? 1 : 0.5
    }
}
