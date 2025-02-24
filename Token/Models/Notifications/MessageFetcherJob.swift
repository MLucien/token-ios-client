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
import PromiseKit

@objc(OWSMessageFetcherJob)
class MessageFetcherJob: NSObject {

    let TAG = "[MessageFetcherJob]"
    var timer: Timer?

    // MARK: injected dependencies
    let networkManager: TSNetworkManager
    let messagesManager: TSMessagesManager
    let messageSender: MessageSender
    let signalService: OWSSignalService

    var runPromises = [Double: Promise<Void>]()

    init(messagesManager: TSMessagesManager, messageSender: MessageSender, networkManager: TSNetworkManager, signalService: OWSSignalService) {
        self.messagesManager = messagesManager
        self.networkManager = networkManager
        self.messageSender = messageSender
        self.signalService = signalService
    }

    func runAsync() {
        NSLog("\(TAG) \(#function)")
        guard signalService.isCensored else {
            NSLog("\(self.TAG) delegating message fetching to SocketManager since we're using normal transport.")
            TSSocketManager.becomeActive(fromBackgroundExpectMessage: true)
            return
        }

        NSLog("\(TAG) using fallback message fetching.")

        let promiseId = NSDate().timeIntervalSince1970
        NSLog("\(self.TAG) starting promise: \(promiseId)")
        let runPromise = self.fetchUndeliveredMessages().then { (envelopes: [OWSSignalServiceProtosEnvelope], more: Bool) -> Void in
            for envelope in envelopes {
                NSLog("\(self.TAG) received envelope.")
                self.messagesManager.handleReceivedEnvelope(envelope)

                self.acknowledgeDelivery(envelope: envelope)
            }
            if more {
                NSLog("\(self.TAG) more messages, so recursing.")
                // recurse
                self.runAsync()
            }
        }.always {
            NSLog("\(self.TAG) cleaning up promise: \(promiseId)")
            self.runPromises[promiseId] = nil
        }

        // maintain reference to make sure it's not de-alloced prematurely.
        self.runPromises[promiseId] = runPromise
    }

    // use in DEBUG or wherever you can't receive push notifications to poll for messages.
    // Do not use in production.
    func startRunLoop(timeInterval: Double) {
        NSLog("\(TAG) Starting message fetch polling. This should not be used in production.")
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.runAsync), userInfo: nil, repeats: true)
    }

    func stopRunLoop() {
        self.timer?.invalidate()
        self.timer = nil
    }

    func parseMessagesResponse(responseObject: Any?) -> (envelopes: [OWSSignalServiceProtosEnvelope], more: Bool)? {
        guard let responseObject = responseObject else {
            NSLog("\(self.TAG) response object was surpringly nil")
            return nil
        }

        guard let responseDict = responseObject as? [String: Any] else {
            NSLog("\(self.TAG) response object was not a dictionary")
            return nil
        }

        guard let messageDicts = responseDict["messages"] as? [[String: Any]] else {
            NSLog("\(self.TAG) messages object was not a list of dictionaries")
            return nil
        }

        let moreMessages = { () -> Bool in
            if let responseMore = responseDict["more"] as? Bool {
                return responseMore
            } else {
                NSLog("\(self.TAG) more object was not a bool. Assuming no more")
                return false
            }
        }()

        let envelopes = messageDicts.map { buildEnvelope(messageDict: $0) }.filter { $0 != nil }.map { $0! }

        return (
            envelopes: envelopes,
            more: moreMessages
        )
    }

    func buildEnvelope(messageDict: [String: Any]) -> OWSSignalServiceProtosEnvelope? {
        let builder = OWSSignalServiceProtosEnvelopeBuilder()

        guard let typeInt = messageDict["type"] as? Int32 else {
            NSLog("\(TAG) message body didn't have type")
            return nil
        }

        guard let type = OWSSignalServiceProtosEnvelopeType(rawValue: typeInt) else {
            NSLog("\(TAG) message body type was invalid")
            return nil
        }
        builder.setType(type)

        if let relay = messageDict["relay"] as? String {
            builder.setRelay(relay)
        }

        guard let timestamp = messageDict["timestamp"] as? UInt64 else {
            NSLog("\(TAG) message body didn't have timestamp")
            return nil
        }
        builder.setTimestamp(timestamp)

        guard let source = messageDict["source"] as? String else {
            NSLog("\(TAG) message body didn't have source")
            return nil
        }
        builder.setSource(source)

        guard let sourceDevice = messageDict["sourceDevice"] as? UInt32 else {
            NSLog("\(TAG) message body didn't have sourceDevice")
            return nil
        }
        builder.setSourceDevice(sourceDevice)

        if let encodedLegacyMessage = messageDict["message"] as? String {
            NSLog("\(TAG) message body had legacyMessage")
            if let legacyMessage = Data(base64Encoded: encodedLegacyMessage) {
                builder.setLegacyMessage(legacyMessage)
            }
        }

        if let encodedContent = messageDict["content"] as? String {
            NSLog("\(TAG) message body had content")
            if let content = Data(base64Encoded: encodedContent) {
                builder.setContent(content)
            }
        }

        return builder.build()
    }

    func fetchUndeliveredMessages() -> Promise<(envelopes: [OWSSignalServiceProtosEnvelope], more: Bool)> {
        return Promise { fulfill, reject in
            let messagesRequest = OWSGetMessagesRequest()

            self.networkManager.makeRequest(
                messagesRequest,
                success: { (_: URLSessionDataTask?, responseObject: Any?) -> Void in
                    guard let (envelopes, more) = self.parseMessagesResponse(responseObject: responseObject) else {
                        NSLog("\(self.TAG) response object had unexpected content")
                        return reject(OWSErrorMakeUnableToProcessServerResponseError())
                    }

                    fulfill((envelopes: envelopes, more: more))
                },
                failure: { (_: URLSessionDataTask?, error: Error?) in
                    guard let error = error else {
                        NSLog("\(self.TAG) error was surpringly nil. sheesh rough day.")
                        return reject(OWSErrorMakeUnableToProcessServerResponseError())
                    }

                    reject(error)
            })
        }
    }

    func acknowledgeDelivery(envelope: OWSSignalServiceProtosEnvelope) {
        let request = OWSAcknowledgeMessageDeliveryRequest(source: envelope.source, timestamp: envelope.timestamp)
        self.networkManager.makeRequest(request,
                                        success: { (_: URLSessionDataTask?, _: Any?) -> Void in
                                            NSLog("\(self.TAG) acknowledged delivery for message at timestamp: \(envelope.timestamp)")
                                        },
                                        failure: { (_: URLSessionDataTask?, error: Error?) in
                                            NSLog("\(self.TAG) acknowledging delivery for message at timestamp: \(envelope.timestamp) failed with error: \(String(describing: error))")
        })
    }
}
