////
///  SettingsToggleButton.swift
//

class SettingsToggleButton: StyledButton {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 30)
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
