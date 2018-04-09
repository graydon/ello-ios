////
///  ShareViewController.swift
//

import Social
import KeychainAccess
import SwiftyUserDefaults
import Moya
import Alamofire
import MobileCoreServices


class ShareViewController: SLComposeServiceViewController {

    var itemPreviews: [ExtensionItemPreview] = []
    var itemsProcessed = false
    fileprivate lazy var background: UIView = self.createBackground()

    fileprivate func createBackground() -> UIView {
        let view = UIView()
        view.alpha = 0
        view.backgroundColor = .black
        view.frame = self.view.frame
        return view
    }

    override func presentationAnimationDidFinish() {
        guard checkIfLoggedIn() else {
            return
        }

        processAttachments()

        super.presentationAnimationDidFinish()
    }

    override func isContentValid() -> Bool {
        return itemsProcessed && ShareAttachmentProcessor.hasContent(contentText, extensionItem: extensionContext?.inputItems.safeValue(0) as? NSExtensionItem)
    }

    override func didSelectPost() {
        showSpinner()
        let content = ShareRegionProcessor.prepContent(contentText, itemPreviews: itemPreviews)
        postContent(content)
    }
}

private extension ShareViewController {

    func processAttachments() {
        guard let extensionItem = extensionContext?.inputItems.safeValue(0) as? NSExtensionItem else {
            finishProcessing()
            return
        }

        inBackground {
            ShareAttachmentProcessor.preview(extensionItem) { previews in
                inForeground {
                    self.itemPreviews = previews
                    self.finishProcessing()
                }
            }
        }
    }

    private func finishProcessing() {
        itemsProcessed = true
        validateContent()
    }

    func showSpinner() {
        view.addSubview(background)
        animate {
            self.background.alpha = 0.5
        }
        inForeground {
            ElloHUD.showLoadingHudInView(self.view)
        }
    }

    func postContent(_ content: [PostEditingService.PostContentRegion]) {
        PostEditingService().create(content: content)
            .done { post in
                Tracker.shared.shareSuccessful()
                self.dismissPostingForm()
            }
            .catch { error in
                Tracker.shared.shareFailed()
                self.showFailedToPost()
            }
            .finally {
                self.donePosting()
            }
    }

    func donePosting() {
        inForeground {
            ElloHUD.hideLoadingHudInView(self.view)
            self.background.removeFromSuperview()
        }
    }

    func dismissPostingForm() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    func checkIfLoggedIn() -> Bool {
        if !AuthToken().isPasswordBased {
            showNotSignedIn()
        }
        return AuthToken().isPasswordBased
    }

    func showFailedToPost() {
        let message = InterfaceString.Share.FailedToPost
        let failedVC = AlertViewController(message: message)
        let cancelAction = AlertAction(title: InterfaceString.Cancel, style: .light) {
            action in
            if let context = self.extensionContext {
                let error = NSError(domain: "co.ello.Ello", code: 0, userInfo: nil)
                context.cancelRequest(withError: error)
            }
        }

        let retryAction = AlertAction(title: InterfaceString.Retry, style: .dark) {
            action in
            self.didSelectPost()
        }

        failedVC.addAction(retryAction)
        failedVC.addAction(cancelAction)
        self.present(failedVC, animated: true, completion: nil)
    }

    func showNotSignedIn() {
        let message = InterfaceString.Share.PleaseLogin
        let notSignedInVC = AlertViewController(confirmation: message) { _ in
            guard let context = self.extensionContext else { return }
            let error = NSError(domain: "co.ello.Ello", code: 0, userInfo: nil)
            context.cancelRequest(withError: error)
        }
        self.present(notSignedInVC, animated: true, completion: nil)
    }
}
