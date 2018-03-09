////
///  BioTextView.swift
//

class BioTextView: UITextView {
    required override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        sharedSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedSetup()
    }

    func sharedSetup() {
        backgroundColor = .greyE5
        clipsToBounds = true
        layer.cornerRadius = ElloTextFieldView.Size.cornerRadius
        font = .defaultFont()
        textColor = .black
        contentInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        scrollsToTop = false
    }
}
