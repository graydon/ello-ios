////
///  SettingsGenerator.swift
//

class SettingsGenerator {
    var currentUser: User
    weak var delegate: SettingsGeneratorDelegate?
    init(currentUser: User) {
        self.currentUser = currentUser
    }

    func load(reload: Bool) {
        loadCurrentUser()
        loadSettings()
        loadCategories()
    }

    func loadCurrentUser() {
        ProfileService().loadCurrentUser()
            .then { user -> Void in
                self.delegate?.currentUserReloaded(user)
            }
            .ignoreErrors
    }

    func loadSettings() {
        SettingsService().dynamicSettings(currentUser: currentUser)
            .then { settingsCategories -> Void in
                self.delegate?.dynamicSettingsLoaded(settingsCategories)
            }
            .ignoreErrors()
    }

    func loadCategories() {
        CategoryService().loadCreatorCategories()
            .then { categories -> Void in
                self.delegate?.categoriesLoaded(categories)
            }
            .ignoreErrors()
    }
}
