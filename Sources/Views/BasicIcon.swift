////
///  BasicIcon.swift
//

class BasicIcon: UIView {
    override var intrinsicContentSize: CGSize { return frame.size }

    private var _enabled = false
    private var _selected = false
    private var _highlighted = false

    private let normalIconView: UIView
    private let selectedIconView: UIView
    private let disabledIconView: UIView?

    // MARK: Initializers

    init(normalIconView: UIView, selectedIconView: UIView, disabledIconView: UIView? = nil) {
        normalIconView.sizeToFit()

        self.normalIconView = normalIconView
        self.selectedIconView = selectedIconView
        self.disabledIconView = disabledIconView

        let frame = CGRect(
            x: 0,
            y: 0,
            width: normalIconView.frame.size.width,
            height: normalIconView.frame.size.height
        )
        super.init(frame: frame)
        addSubview(self.normalIconView)
        addSubview(self.selectedIconView)
        self.selectedIconView.isHidden = true

        if let view = disabledIconView {
            addSubview(view)
            view.isHidden = true
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateIcon(selected: Bool, enabled: Bool) {
        if let disabledIconView = disabledIconView {
            normalIconView.isVisible = (enabled && !selected)
            selectedIconView.isVisible = (enabled && selected)
            disabledIconView.isHidden = enabled
        }
        else {
            normalIconView.isHidden = selected
            selectedIconView.isVisible = selected
        }
    }
}

extension BasicIcon: ImageLabelAnimatable {

    var isEnabled: Bool {
        get { return _enabled }
        set {
            _enabled = newValue
            updateIcon(selected: _selected, enabled: newValue)
        }
    }

    var isSelected: Bool {
        get { return _selected }
        set {
            _selected = newValue
            updateIcon(selected: newValue, enabled: _enabled)
        }
    }

    var isHighlighted: Bool {
        get { return _highlighted }
        set {
            _highlighted = newValue
            if isSelected { return }
            updateIcon(selected: newValue, enabled: _enabled)
        }
    }

    var view: UIView { return self }
}
