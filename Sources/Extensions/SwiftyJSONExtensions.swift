////
///  SwiftyJSONExtensions.swift
//

import SwiftyJSON

extension JSON {
    public var id: String? {
        get {
            if let string = string {
                return string
            }
            if let int = int {
                return "\(int)"
            }
            return nil
        }
        set {
            string = newValue
        }
    }
}
