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

import Foundation
import KeychainSwift

protocol Singleton: class {
    static var sharedInstance: Self { get }
}

/// Thin YapDatabase wrapper. Use this to store local user data safely.
public final class Yap: NSObject, Singleton {
    var database: YapDatabase

    public var mainConnection: YapDatabaseConnection

    public static let sharedInstance = Yap()

    private var databasePassword: Data

    private let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(".Signal.sqlite").path

    private override init() {
        let options = YapDatabaseOptions()
        options.corruptAction = .fail

        let keychain = KeychainSwift()
        var databasePassword: Data

        if let dbPwd = keychain.getData("DBPWD") {
            options.cipherKeyBlock = {
                dbPwd
            }

            databasePassword = dbPwd
        } else {
            databasePassword = Randomness.generateRandomBytes(60).base64EncodedString().data(using: .utf8)!

            keychain.set(databasePassword, forKey: "DBPWD")
            options.cipherKeyBlock = {
                databasePassword
            }
        }

        self.databasePassword = databasePassword

        self.database = YapDatabase(path: self.path, options: options)

        self.mainConnection = self.database.newConnection()
    }

    public func wipeStorage() {
        KeychainSwift().delete("DBPWD")
        try! FileManager.default.removeItem(atPath: self.path)
    }

    /// Insert a object into the database using the main thread default connection.
    ///
    /// - Parameters:
    ///   - object: Object to be stored. Must be serialisable. If nil, delete the record from the database.
    ///   - key: Key to store and retrieve object.
    ///   - collection: Optional. The name of the collection the object belongs to. Helps with organisation.
    ///   - metadata: Optional. Any serialisable object. Could be a related object, a description, a timestamp, a dictionary, and so on.
    public final func insert(object: Any?, for key: String, in collection: String? = nil, with metadata: Any? = nil) {
        self.mainConnection.readWrite { transaction in
            transaction.setObject(object, forKey: key, inCollection: collection, withMetadata: metadata)
        }
    }

    public final func removeObject(for key: String, in collection: String? = nil) {
        self.mainConnection.readWrite { transaction in
            transaction.removeObject(forKey: key, inCollection: collection)
        }
    }

    /// Checks whether an object was stored for a given key inside a given (optional) collection.
    ///
    /// - Parameter key: Key to check for the presence of a stored object.
    /// - Returns: Bool whether or not a certain object was stored for that key.
    public final func containsObject(for key: String, in collection: String? = nil) -> Bool {
        return self.retrieveObject(for: key, in: collection) != nil
    }

    /// Retrieve an object for a given key inside a given (optional) collection.
    ///
    /// - Parameters:
    ///   - key: Key used to store the object
    ///   - collection: Optional. The name of the collection the object was stored in.
    /// - Returns: The stored object.
    public final func retrieveObject(for key: String, in collection: String? = nil) -> Any? {
        var object: Any?
        self.mainConnection.read { transaction in
            object = transaction.object(forKey: key, inCollection: collection)
        }

        return object
    }

    /// Retrieve all objects from a given collection.
    ///
    /// - Parameters:
    ///   - collection: The name of the collection to be retrieved.
    /// - Returns: The stored objects inside the collection.
    public final func retrieveObjects(in collection: String) -> [Any] {
        var objects = [Any]()

        self.mainConnection.read { transaction in
            transaction.enumerateKeysAndObjects(inCollection: collection) { _, object, _ in
                objects.append(object)
            }
        }

        return objects
    }
}
