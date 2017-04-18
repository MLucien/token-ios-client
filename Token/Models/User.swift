// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import SweetSwift
import KeychainSwift

public protocol JSONDataSerialization {
    var JSONData: Data { get }
}

/// Current User. Responsible for current session management.
public class User: NSObject, JSONDataSerialization {

    private static let storedUserKey = "StoredUser"

    var balance = NSDecimalNumber.zero

    private static var _current: User?

    public static var current: User? {
        get {
            if let userData = (Yap.sharedInstance.retrieveObject(for: User.storedUserKey) as? Data), self._current == nil,
                let deserialised = (try? JSONSerialization.jsonObject(with: userData, options: [])),
                let json = deserialised as? [String: Any] {

                self._current = User(json: json)
            }

            return self._current
        }
        set {
            newValue?.update()

            if let user = newValue {
                let keychain = KeychainSwift()
                keychain.set(user.paymentAddress, forKey: "CurrentUserPaymentAddress")

                Yap.sharedInstance.insert(object: user.JSONData, for: User.storedUserKey)
            }

            self._current = newValue
        }
    }

    private var _avatar: UIImage?

    private(set) public var username: String

    private(set) public var name: String

    private(set) public var about: String

    private(set) public var location: String

    private(set) public var avatarPath: String

    public var avatar: UIImage? {
        IDAPIClient.shared.downloadAvatar(path: self.avatarPath, fromCache: false) { image in
            self._avatar = image
        }

        return self._avatar
    }

    public let address: String

    public let paymentAddress: String

    public var JSONData: Data {
        return try! JSONSerialization.data(withJSONObject: self.asDict, options: [])
    }

    public var asDict: [String: Any] {
        return [
            "token_id": self.address,
            "payment_address": self.paymentAddress,
            "username": self.username,
            "about": self.about,
            "location": self.location,
            "name": self.name,
            "avatar": self.avatarPath,
        ]
    }

    init(json: [String: Any]) {
        self.address = json["token_id"] as! String
        self.paymentAddress = (json["payment_address"] as? String) ?? (json["token_id"] as! String)
        self.username = json["username"] as! String
        self.name = json["name"] as? String ?? ""
        self.location = json["location"] as? String ?? ""
        self.about = json["about"] as? String ?? ""
        self.avatarPath = json["avatar"] as? String ?? ""

        super.init()

        self.update()
    }

    public func update(avatar: UIImage, avatarPath: String) {
        self.avatarPath = avatarPath
        self._avatar = avatar
        self.save()
    }

    public func update(username: String? = nil, name _: String? = nil, about _: String? = nil, location _: String? = nil) {
        self.username = username ?? self.username
        self.name = username ?? self.name
        self.about = username ?? self.about
        self.location = username ?? self.location
        self.save()
    }

    public func save() {
        Yap.sharedInstance.insert(object: self.JSONData, for: User.storedUserKey)
    }

    public override var description: String {
        return "<User: address: \(self.address), payment address: \(self.paymentAddress), name: \(self.name), username: \(self.username)>"
    }
}
