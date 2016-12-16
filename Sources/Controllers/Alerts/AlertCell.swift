////
///  AlertCell.swift
//

import UIKit
import Foundation
import ElloUIFonts
import CoreGraphics

public protocol AlertCellDelegate: class {
    func tappedOkButton()
    func tappedCancelButton()
}

public class AlertCell: UITableViewCell {
    static let reuseIdentifier = "AlertCell"

    weak var delegate: AlertCellDelegate?

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var input: ElloTextField!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var okButton: StyledButton!
    @IBOutlet weak var cancelButton: StyledButton!
    let inputBorder = UIView()

    var onInputChanged: ((String) -> Void)?

    override public func awakeFromNib() {
        super.awakeFromNib()

        label.font = .defaultFont()
        label.textColor = .blackColor()
        label.textAlignment = .Left

        input.backgroundColor = UIColor.whiteColor()
        input.font = UIFont.defaultFont()
        input.textColor = UIColor.blackColor()
        input.tintColor = UIColor.blackColor()
        input.clipsToBounds = false

        inputBorder.backgroundColor = UIColor.blackColor()
        input.addSubview(inputBorder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        inputBorder.frame = input.bounds.fromBottom().grow(top: 1, sides: 10, bottom: 0)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        label.text = ""
        label.textColor = .blackColor()
        label.textAlignment = .Left
        input.text = ""
        input.resignFirstResponder()
    }
}

extension AlertCell {
    @IBAction func didUpdateInput() {
        onInputChanged?(input.text ?? "")
    }

    @IBAction func didTapOkButton() {
        delegate?.tappedOkButton()
    }

    @IBAction func didTapCancelButton() {
        delegate?.tappedCancelButton()
    }

}

extension AlertCell {
    class func nib() -> UINib {
        return UINib(nibName: "AlertCell", bundle: .None)
    }
}
