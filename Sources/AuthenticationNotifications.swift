////
///  Notifications.swift
//

struct AuthenticationNotifications {
    static let userLoggedOut = TypedNotification<Void>(name: "UserElloLoggedOutNotification")
    static let invalidToken = TypedNotification<Void>(name: "ElloInvalidTokenNotification")
    static let outOfDateAPI = TypedNotification<Void>(name: "ElloInvalidTokenNotification")
}
