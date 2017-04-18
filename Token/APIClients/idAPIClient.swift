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
import AwesomeCache
import SweetFoundation
import Teapot

public class IDAPIClient: NSObject, CacheExpiryDefault {
    public static let shared: IDAPIClient = IDAPIClient()

    public static let usernameValidationPattern = "^[a-zA-Z][a-zA-Z0-9_]+$"

    public static let updateContactsNotification = Notification.Name(rawValue: "UpdateContactWithAddress")

    public static let didFetchContactInfoNotification = Notification.Name(rawValue: "DidFetchContactInfo")

    public var teapot: Teapot

    private var imageCache = try! Cache<UIImage>(name: "imageCache")

    private var contactCache = try! Cache<TokenContact>(name: "tokenContactCache")

    let contactUpdateQueue = DispatchQueue(label: "token.updateContactsQueue")

    public var baseURL: URL

    private override init() {
        self.baseURL = URL(string: TokenIdServiceBaseURLPath)!
        self.teapot = Teapot(baseURL: self.baseURL)

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(IDAPIClient.updateContacts), name: IDAPIClient.updateContactsNotification, object: nil)
    }

    /// We use a background queue and a semaphore to ensure we only update the UI
    /// once all the contacts have been processed.
    func updateContacts() {
        self.contactUpdateQueue.async {
            guard let contactsData = Yap.sharedInstance.retrieveObjects(in: TokenContact.collectionKey) as? [Data] else { fatalError() }
            let semaphore = DispatchSemaphore(value: 0)

            for contactData in contactsData {
                guard let dictionary = try? JSONSerialization.jsonObject(with: contactData, options: []) else { continue }

                if let dictionary = dictionary as? [String: Any] {
                    let tokenContact = TokenContact(json: dictionary)
                    self.findContact(name: tokenContact.address) { _ in
                        semaphore.signal()
                    }
                    // calls to `wait()` need to be balanced with calls to `signal()`
                    // remember to call it _after_ the code we need to run asynchronously.
                    _ = semaphore.wait(timeout: .distantFuture)
                }
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: TokenContact.didUpdateContactInfoNotification, object: self)
            }
        }
    }

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {
        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError() }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp should be an integer") }

                completion(timestamp)
            case .failure(_, let response, _):
                print(response)
                fatalError()
            }
        }
    }

    public func registerUserIfNeeded(_ success: @escaping (() -> Void)) {
        self.retrieveUser(username: Cereal.shared.address) { user in
            guard user == nil else {
                User.current = user

                return
            }

            self.fetchTimestamp { timestamp in
                let cereal = Cereal.shared
                let path = "/v1/user"
                let parameters = [
                    "payment_address": cereal.paymentAddress,
                ]
                let parametersString = String(data: try! JSONSerialization.data(withJSONObject: parameters, options: []), encoding: .utf8)!
                let hashedParameters = cereal.sha3WithID(string: parametersString)
                let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedParameters)"))"

                let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

                let json = RequestParameter(parameters)
                self.teapot.post(path, parameters: json, headerFields: fields) { result in
                    switch result {
                    case .success(let json, let response):
                        guard response.statusCode == 200 else { return }
                        guard let json = json?.dictionary else { return }

                        User.current = User(json: json)
                        print("Registered user with address: \(cereal.address)")

                        success()
                    case .failure(let json, let response, let error):
                        print(response)
                        print(error)
                        print(json ?? "")
                    }
                }
            }
        }
    }

    public func updateAvatar(_ avatar: UIImage, completion: @escaping ((_ success: Bool) -> Void)) {
        self.fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/user"
            let boundary = "teapot.boundary"
            let payload = self.teapot.multipartData(from: avatar, boundary: boundary, filename: "avatar.png")
            let hashedPayload = cereal.sha3WithID(data: payload)
            let signature = "0x\(cereal.signWithID(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp), "Content-Length": String(describing: payload.count), "Content-Type": "multipart/form-data; boundary=\(boundary)"]
            let json = RequestParameter(payload)

            self.teapot.put(path, parameters: json, headerFields: fields) { result in
                switch result {
                case .success(let json, _):
                    guard let userDict = json?.dictionary else { completion(false); return }

                    User.current?.update(avatar: avatar, avatarPath: userDict["avatar"] as! String)

                    completion(true)
                case .failure(_, _, let error):
                    // TODO: show error
                    print(error)
                    completion(false)
                }
            }
        }
    }

    public func updateUser(_ user: User, completion: @escaping ((_ success: Bool, _ message: String?) -> Void)) {
        self.fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let path = "/v1/user"
            let payload = user.JSONData
            let payloadString = String(data: payload, encoding: .utf8)!

            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = RequestParameter(user.asDict)

            self.teapot.put("/v1/user", parameters: json, headerFields: fields) { result in
                switch result {
                case .success(let json, let response):
                    guard response.statusCode == 200 else { fatalError() }
                    guard let json = json?.dictionary else { fatalError() }

                    let user = User(json: json)
                    User.current = user

                    completion(true, nil)
                case .failure(let json, _, _):
                    let errors = json?.dictionary?["errors"] as? [[String: Any]]
                    let message = errors?.first?["message"] as? String
                    completion(false, message)
                }
            }
        }
    }

    public func retrieveContact(username: String, completion: @escaping ((TokenContact?) -> Void)) {
        self.teapot.get("/v1/user/\(username)", headerFields: ["Token-Timestamp": String(Int(Date().timeIntervalSince1970))]) { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                // we know it's a dictionary for this API
                guard let json = json?.dictionary else { completion(nil); return }
                let contact = TokenContact(json: json)

                completion(contact)
            case .failure(let json, let response, let error):
                print(error.localizedDescription)
                print(response)
                print(json?.dictionary ?? "")

                completion(nil)
            }
        }
    }

    public func retrieveUser(username: String, completion: @escaping ((User?) -> Void)) {
        self.teapot.get("/v1/user/\(username)", headerFields: ["Token-Timestamp": String(Int(Date().timeIntervalSince1970))]) { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                // we know it's a dictionary for this API
                guard let json = json?.dictionary else { completion(nil); return }
                let user = User(json: json)

                print("Current user with address: \(user.address)")

                completion(user)
            case .failure(let json, let response, let error):
                print(error.localizedDescription)
                print(response)
                print(json?.dictionary ?? "")

                completion(nil)
            }
        }
    }

    func downloadAvatar(path: String, fromCache: Bool = true, completion: @escaping (_ image: UIImage?) -> Void) {
        if fromCache {
            self.imageCache.setObject(forKey: path, cacheBlock: { success, failure in
                let teapot = Teapot(baseURL: URL(string: path)!)
                teapot.get { (result: NetworkImageResult) in
                    switch result {
                    case .success(let image, _):
                        success(image, self.cacheExpiry)
                    case .failure(let response, let error):
                        print(response)
                        print(error)
                        failure(error as NSError)
                    }
                }
            }) { image, _, _ in
                completion(image)
            }
        } else {
            let teapot = Teapot(baseURL: URL(string: path)!)
            teapot.get { (result: NetworkImageResult) in
                switch result {
                case .success(let image, _):
                    completion(image)
                case .failure(let response, let error):
                    print(response)
                    print(error)
                    completion(nil)
                }
            }
        }
    }

    public func findContact(name: String, completion: @escaping ((TokenContact?) -> Void)) {
        self.contactCache.setObject(forKey: name, cacheBlock: { success, failure in
            self.teapot.get("/v1/user/\(name)") { (result: NetworkResult) in
                switch result {
                case .success(let json, let response):
                    print(response)
                    guard let json = json?.dictionary else { completion(nil); return }

                    let contact = TokenContact(json: json)
                    NotificationCenter.default.post(name: IDAPIClient.didFetchContactInfoNotification, object: contact)

                    success(contact, self.cacheExpiry)
                case .failure(_, let response, let error):
                    if response.statusCode == 404 {
                        // contact was deleted from the server. If we don't have it locally, delete the signal thread.
                        if !Yap.sharedInstance.containsObject(for: name, in: TokenContact.collectionKey) {
                            TSStorageManager.shared().dbConnection.readWrite { transaction in
                                let thread = TSContactThread.getOrCreateThread(withContactId: name, transaction: transaction)
                                thread.archiveThread(with: transaction)
                            }
                        }
                    }
                    print(error.localizedDescription)

                    failure(error as NSError)
                }
            }
        }) { contact, _, _ in
            completion(contact)
        }
    }

    public func searchContacts(name: String, completion: @escaping (([TokenContact]) -> Void)) {
        // /v1/search/user/?query=moxiemarl&offset=80&limit=20
        self.teapot.get("/v1/search/user?query=\(name)") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)

                guard let dictionary = json?.dictionary, let json = dictionary["results"] as? [[String: Any]] else { completion([]); return }

                var contacts = [TokenContact]()
                for item in json {
                    contacts.append(TokenContact(json: item))
                }
                completion(contacts)
            case .failure(_, let response, let error):
                print(response)
                print(error.localizedDescription)
                completion([])
            }
        }
    }
}
