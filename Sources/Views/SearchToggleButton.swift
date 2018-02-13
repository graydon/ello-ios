////
///  SearchToggleButton.swift
//

import SnapKit


class SearchToggleButton: Button {
    struct Size {
        static let lineHeight: CGFloat = 1
    }

    private let line = UIView()
    override var isSelected: Bool {
        didSet {
            self.updateLineColor()
        }
    }

    override func style() {
        titleLabel?.font = .defaultFont()
        setTitleColor(.greyA, for: .normal)
        setTitleColor(.black, for: .selected)
        updateLineColor()
    }

    override func arrange() {
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(Size.lineHeight)
        }
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        elloAnimate(animated: animated) {
            self.isSelected = selected
        }
    }

    private func updateLineColor() {
        line.backgroundColor = isSelected ? .black : .greyF2
    }
}
