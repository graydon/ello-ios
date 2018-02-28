////
///  ManageCategoriesScreen.swift
//

class ManageCategoriesScreen: StreamableScreen, ManageCategoriesScreenProtocol {
    weak var delegate: ManageCategoriesScreenDelegate?

    override func style() {
        navigationBar.leftItems = [.back]
        navigationBar.rightItems = [.close]
    }

}
