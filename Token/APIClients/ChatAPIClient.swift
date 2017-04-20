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
import Teapot
import SweetFoundation

public class ChatAPIClient: NSObject {

    static let shared: ChatAPIClient = ChatAPIClient()

    public var teapot: Teapot

    public var baseURL: URL

    public lazy var storageManager: TSStorageManager = {
        TSStorageManager.shared()
    }()

    private override init() {
        let tokenChatServiceBaseURL = Bundle.main.object(forInfoDictionaryKey: "TokenChatServiceBaseURL") as! String
        self.baseURL = URL(string: tokenChatServiceBaseURL)!
        self.teapot = Teapot(baseURL: self.baseURL)

        super.init()
    }

    func fetchTimestamp(_ completion: @escaping ((Int) -> Void)) {
        self.teapot.get("/v1/accounts/bootstrap/") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError("Could not retrieve timestamp from chat service.") }
                guard let json = json?.dictionary else { fatalError("JSON dictionary not found in payload") }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp not found in json payload or not an integer.") }

                completion(timestamp)
            case .failure(let json, let response, let error):
                print(error)
                print(response)
                print(json ?? "")
            }
        }
    }

    public func registerUser() {
        self.fetchTimestamp { timestamp in
            let cereal = Cereal.shared
            let parameters = UserBootstrapParameter(storageManager: self.storageManager)
            let path = "/v1/accounts/bootstrap"
            let payload = parameters.payload
            let payloadString = String(data: try! JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8)!
            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let message = "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(cereal.signWithID(message: message))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let requestParameter = RequestParameter(payload)

            self.teapot.put(path, parameters: requestParameter, headerFields: fields) { result in
                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        print("Could not register user. Status code \(response.statusCode)")

                        return
                    }

                    TSStorageManager.storeServerToken(parameters.password, signalingKey: parameters.signalingKey)
                    print("Successfully registered chat user with address: \(cereal.address)")
                case .failure(let json, let response, let error):
                    print(json ?? "")
                    print(response)
                    print(error)
                }
            }
        }
    }

    func authToken(for address: String, password: String) -> String {
        return "Basic \("\(address):\(password)".data(using: .utf8)!.base64EncodedString())"
    }
}
