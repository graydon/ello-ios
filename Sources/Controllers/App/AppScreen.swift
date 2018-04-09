////
///  AppScreen.swift
//

import SnapKit


class AppScreen: EmptyScreen {
    private var logoImage = GradientLoadingView()

    override func arrange() {
        super.arrange()
        addSubview(logoImage)

        logoImage.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self)
        }
    }
}

extension AppScreen: AppScreenProtocol {
    func animateLogo() {
        logoImage.startAnimating()
    }

    func stopAnimatingLogo() {
        logoImage.stopAnimating()
    }

    func hide() {
        logoImage.alpha = 0
    }
}
