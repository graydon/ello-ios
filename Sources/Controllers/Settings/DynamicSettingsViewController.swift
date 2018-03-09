////
///  DynamicSettingsViewController.swift
//

class DynamicSettingsViewController: BaseElloViewController {
    private var _mockScreen: DynamicSettingsScreenProtocol?
    var screen: DynamicSettingsScreenProtocol {
        set(screen) { _mockScreen = screen }
        get { return fetchScreen(_mockScreen) }
    }

    let category: DynamicSettingCategory

    init(category: DynamicSettingCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let screen = DynamicSettingsScreen(settings: category.settings)
        screen.delegate = self
        screen.title = category.label
        view = screen
        screen.reload()
    }

    override func didSetCurrentUser() {
        super.didSetCurrentUser()
        if isViewLoaded {
            screen.reload()
        }
    }
}

extension DynamicSettingsViewController: DynamicSettingsScreenDelegate {
}

extension DynamicSettingsViewController: DynamicSettingCellResponder {
    func toggleSetting(_ setting: DynamicSetting, value: Bool) {
        guard
            let settingKey = Profile.Property(rawValue: setting.key)
        else { return }

        var updatedValues: [Profile.Property: Any] = [
            settingKey: value,
        ]
        for anotherSetting in category.settings {
            guard
                let anotherValue = setting.sets(anotherSetting, when: value),
                let anotherKey = Profile.Property(rawValue: anotherSetting.key)
            else { continue }

            updatedValues[anotherKey] = anotherValue
        }

        ProfileService().updateUserProfile(updatedValues)
            .then { [weak self] user -> Void in
                guard let `self` = self else { return }

                self.appViewController?.currentUser = user
            }
            .always { [weak self] in
                self?.screen.reload()
            }
    }

    func deleteAccount() {
        let vc = DeleteAccountConfirmationViewController()
        present(vc, animated: true, completion: nil)
    }
}
