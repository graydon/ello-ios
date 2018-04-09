////
///  DeleteAccountConfirmationViewController.swift
//

private enum DeleteAccountState {
    case askNicely
    case areYouSure
    case noTurningBack
}

class DeleteAccountConfirmationViewController: BaseElloViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: StyledLabel!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var cancelView: UIView!
    @IBOutlet weak var cancelLabel: StyledLabel!

    private var state: DeleteAccountState = .askNicely
    private var timer: Timer?
    private var counter = 5

    init() {
        super.init(nibName: "DeleteAccountConfirmationView", bundle: Bundle(for: DeleteAccountConfirmationViewController.self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = "* \(InterfaceString.Settings.DeleteAccountExplanation)"
        cancelLabel.textAlignment = .center
        cancelLabel.textColor = .white

        updateInterface()
    }

    private func updateInterface() {
        switch state {
        case .askNicely:
            let title = InterfaceString.Settings.DeleteAccountConfirm
            titleLabel.text = title

        case .areYouSure:
            let title = InterfaceString.AreYouSure
            titleLabel.text = title
            infoLabel.isVisible = true

        case .noTurningBack:
            let title = InterfaceString.Settings.AccountIsBeingDeleted
            titleLabel.text = title
            titleLabel.font = UIFont(descriptor: titleLabel.font.fontDescriptor, size: 18)
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(DeleteAccountConfirmationViewController.tick), userInfo: .none, repeats: true)
            infoLabel.isHidden = true
            buttonView.isHidden = true
            cancelView.isVisible = true
        }
    }

    @objc
    private func tick() {
        let text = InterfaceString.Settings.RedirectedCountdown(counter)
        nextTick {
            self.cancelLabel.text = text
            self.counter -= 1
            if self.counter <= 0 {
                self.deleteAccount()
            }
        }
    }

    private func deleteAccount() {
        timer?.invalidate()
        ElloHUD.showLoadingHudInView(self.view)

        ProfileService().deleteAccount()
            .done { _ in
                Tracker.shared.userDeletedAccount()
                self.dismiss(animated: true) {
                    postNotification(AuthenticationNotifications.userLoggedOut, value: ())
                }
            }
            .ensure {
                ElloHUD.hideLoadingHudInView(self.view)
            }
            .ignoreErrors()
    }

    @IBAction func yesButtonTapped() {
        switch state {
        case .askNicely: state = .areYouSure
        case .areYouSure: state = .noTurningBack
        default: break
        }
        updateInterface()
    }

    @IBAction private func dismiss() {
        timer?.invalidate()
        self.dismiss(animated: true, completion: nil)
    }
}
