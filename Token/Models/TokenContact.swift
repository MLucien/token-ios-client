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

/// A Token contact. Not to be confused with a (signal) Contact.
/// We use this for our UI and contact management with the ID server.
/// Contact is used by Signal for messaging. They correlate by their address.
/// Contact's phone numbers are actually ethereum addresses for this app.
public class TokenContact: NSObject, JSONDataSerialization, NSCoding {
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let jsonData = aDecoder.decodeObject(forKey: "jsonData") as? Data else { return nil }
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData, options: []), let json = deserialised as? [String: Any] else { return nil }

        self.init(json: json)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.JSONData, forKey: "jsonData")
    }

    public static let didUpdateContactInfoNotification = Notification.Name(rawValue: "DidUpdateContactInfo")

    public static let viewExtensionName = "TokenContactsDatabaseViewExtensionName"

    public static let collectionKey: String = "TokenContacts"

    public var isApp: Bool = false

    public var category = ""

    public var address: String

    public var paymentAddress: String

    public var username: String {
        return "@\(self.name)"
    }

    public var name: String

    public var displayName: String = ""

    public var about: String = ""

    public var location: String = ""

    public var avatarPath: String = ""

    public var avatar: UIImage?

    public var JSONData: Data {
        var imageDataString = ""
        if let image = self.avatar, let data = (UIImagePNGRepresentation(image) ?? UIImageJPEGRepresentation(image, 1.0)) {
            imageDataString = data.hexadecimalString
        }

        let custom: [String: Any] = [
            "name": self.displayName,
            "location": self.location,
            "about": self.about,
            "avatar": self.avatarPath,
            "avatarDataHex": imageDataString,
        ]

        let json: [String: Any] = [
            "token_id": self.address,
            "custom": custom,
            "is_app": self.isApp,
            "username": self.name,
            "payment_address": self.paymentAddress,
        ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    init(json: [String: Any]) {
        self.address = json["token_id"] as! String
        self.paymentAddress = (json["payment_address"] as? String) ?? json["token_id"] as! String
        self.name = json["username"] as! String
        self.isApp = json["is_app"] as! Bool

        if let json = json["custom"] as? [String: Any] {
            self.displayName = (json["name"] as? String) ?? ""
            self.location = (json["location"] as? String) ?? ""
            self.about = (json["about"] as? String) ?? ""
            self.avatarPath = (json["avatar"] as? String) ?? ""

            if let avatarDataHex = (json["avatarDataHex"] as? String), avatarDataHex.length > 0, let hexData = avatarDataHex.hexadecimalData {
                self.avatar = UIImage(data: hexData)
            }
        }

        super.init()

        if self.avatarPath.length > 0 {
            if self.isApp {
                AppsAPIClient.shared.downloadImage(for: self) { image in
                    self.avatar = image
                }
            } else {
                IDAPIClient.shared.downloadAvatar(path: self.avatarPath) { image in
                    self.avatar = image
                }
            }
        }

        self.setupNotifications()
    }

    // calling this with invalid data will crash the app
    static func contact(withData data: Data) -> TokenContact? {
        guard let deserialised = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let json = deserialised as? [String: Any] else { return nil }

        return TokenContact(json: json)
    }

    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateIfNeeded), name: IDAPIClient.didFetchContactInfoNotification, object: nil)
    }

    func updateIfNeeded(_ notification: Notification) {
        guard let tokenContact = notification.object as? TokenContact else { return }
        guard tokenContact.address == self.address else { return }

        if self.name == tokenContact.name && self.displayName == tokenContact.displayName && self.location == tokenContact.location && self.about == tokenContact.about {
            return
        }

        self.name = tokenContact.name
        self.displayName = tokenContact.displayName
        self.location = tokenContact.location
        self.about = tokenContact.about
    }

    public override var description: String {
        return "<TokenContact: address: \(self.address), name: \(self.displayName), username: \(self.name)>"
    }
}
