////
///  ManageCategoriesGenerator.swift
//

class ManageCategoriesGenerator: StreamGenerator {
    var currentUser: User?
    var streamKind: StreamKind = .manageCategories
    weak var destination: StreamDestination?

    init(currentUser: User, destination: StreamDestination?) {
        self.currentUser = currentUser
        self.destination = destination
    }

    func load(reload: Bool) {
        if reload {
        }
        else {
            setPlaceHolders()
        }

        loadAllCategories()
    }
}

extension ManageCategoriesGenerator {
    private func setPlaceHolders() {
        destination?.setPlaceholders(items: [
            StreamCellItem(type: .placeholder, placeholderType: .streamItems)
        ])
    }

    private func loadAllCategories() {
        API().allCategories()
            .execute()
            .then { allCategories -> Void in
                guard let currentUser = self.currentUser else { return }

                let subscribedCategories: [Category] = allCategories.filter { category in
                    return currentUser.subscribedTo(categoryId: category.id)
                }

                let remainingCategories: [Category] = allCategories.filter { category in
                    return subscribedCategories.find({ $0.id == category.id }) == nil
                }

                let subscribedItems = self.parse(jsonables: subscribedCategories)
                let remainingItems = self.parse(jsonables: remainingCategories)
                var items: [StreamCellItem] = [StreamCellItem(type: .fullWidthSpacer(height: 5))]
                if !subscribedItems.isEmpty {
                    items.append(StreamCellItem(type: .header(InterfaceString.Discover.Subscribed)))
                    items.append(StreamCellItem(type: .fullWidthSpacer(height: 10)))
                    items += subscribedItems
                }
                if !remainingItems.isEmpty {
                    items.append(StreamCellItem(type: .header(InterfaceString.Discover.Categories)))
                    items.append(StreamCellItem(type: .fullWidthSpacer(height: 10)))
                    items += remainingItems
                }
                self.destination?.replacePlaceholder(type: .streamItems, items: items)
            }
            .ignoreErrors()
    }
}
