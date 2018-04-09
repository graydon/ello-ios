////
///  ForgotPasswordEmailViewController.swift
//

class ForgotPasswordEmailViewController: BaseElloViewController {
    private var _mockScreen: ForgotPasswordEmailScreenProtocol?
    var screen: ForgotPasswordEmailScreenProtocol {
        set(screen) { _mockScreen = screen}
        get { return fetchScreen(_mockScreen) }
    }

    override func loadView() {
        let screen = ForgotPasswordEmailScreen()
        screen.delegate = self
        view = screen
    }
}

extension ForgotPasswordEmailViewController: ForgotPasswordEmailScreenDelegate {
    func submit(email: String) {
        Tracker.shared.tappedRequestPassword()

        _ = screen.resignFirstResponder()

        if Validator.isValidEmail(email) {
            screen.hideEmailError()
            screen.loadingHUD(visible: true)
            Tracker.shared.requestPasswordValid()

            UserService().requestPasswordReset(email: email)
                .done { _ in
                    self.screen.loadingHUD(visible: false)
                    self.screen.showSubmitMessage()
                }
                .catch { error in
                    self.screen.loadingHUD(visible: false)
                    let errorTitle = error.elloErrorMessage ?? InterfaceString.UnknownError
                    self.screen.showEmailError(errorTitle)
                }
        }
        else {
            if let msg = Validator.invalidSignUpEmailReason(email) {
                screen.showEmailError(msg)
            }
            else {
                screen.hideEmailError()
            }
        }
    }

    func backAction() {
        _ = navigationController?.popViewController(animated: true)
    }

    func validate(email: String) {
        if Validator.invalidSignUpEmailReason(email) == nil {
            screen.isEmailValid = true
        }
        else {
            screen.isEmailValid = nil
        }
    }
}
