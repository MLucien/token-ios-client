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
import SweetUIKit
import NoChat
import MobileCoreServices
import ImagePicker

class ChatController: MessagesCollectionViewController {

    let etherAPIClient = EthereumAPIClient.shared
    let idAPIClient = IDAPIClient.shared

    var textLayoutQueue = DispatchQueue(label: "com.tokenbrowser.token.layout", qos: DispatchQoS(qosClass: .default, relativePriority: 0))

    lazy var rateButton: UIBarButtonItem = {
        let view = UIBarButtonItem(title: "Rate", style: .plain, target: self, action: #selector(didTapRateUser))

        return view
    }()

    var messages = [Message]() {
        didSet {
            let current = Set(self.messages)
            let previous = Set(oldValue)
            let new = current.subtracting(previous).sorted { (message1, message2) -> Bool in
                // so far the only case where this is true to the milisecond is when
                // signal splits a media message into two, with the same dates. That means that one of them has attachments
                // but the other one doesn't. We want the one with attachments on top.
                if message1.date.compare(message2.date) == .orderedSame {
                    return message1.signalMessage.hasAttachments()
                }

                // otherwise, resume regular date comparison
                return message1.date.compare(message2.date) == .orderedAscending
            }

            let displayables = new.filter { (message) -> Bool in
                return message.isDisplayable
            }

            // Only animate if we're adding one message, for bulk-insert we want them instant.
            // let isAnimated = displayables.count == 1
            self.addMessages(displayables, scrollToBottom: true)
        }
    }

    var visibleMessages: [Message] {
        return self.messages.filter { (message) -> Bool in
            message.isDisplayable
        }
    }

    lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [self.thread.uniqueId], view: TSMessageDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    lazy var editingDatabaseConnection: YapDatabaseConnection = {
        self.storageManager.newDatabaseConnection()
    }()

    var thread: TSThread

    var chatAPIClient: ChatAPIClient

    var ethereumAPIClient: EthereumAPIClient

    var messageSender: MessageSender

    var contactsManager: ContactsManager

    var contactsUpdater: ContactsUpdater

    var storageManager: TSStorageManager

    lazy var ethereumPromptView: ChatsFloatingHeaderView = {
        let view = ChatsFloatingHeaderView(withAutoLayout: true)
        view.delegate = self

        return view
    }()

    // MARK: - Class overrides

    override class func cellLayoutClass(forItemType type: String) -> AnyClass? {
        if type == "Text" {
            return MessageCellLayout.self
        } else if type == "Actionable" {
            return ActionableMessageCellLayout.self
        } else if type == "Image" {
            return ImageMessageCellLayout.self
        } else {
            return nil
        }
    }

    // MARK: - Init

    init(thread: TSThread, chatAPIClient: ChatAPIClient, ethereumAPIClient: EthereumAPIClient = .shared) {
        self.chatAPIClient = chatAPIClient
        self.ethereumAPIClient = ethereumAPIClient
        self.thread = thread

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError("Could not retrieve app delegate") }

        self.messageSender = appDelegate.messageSender
        self.contactsManager = appDelegate.contactsManager
        self.contactsUpdater = appDelegate.contactsUpdater
        self.storageManager = TSStorageManager.shared()

        super.init(nibName: nil, bundle: nil)

        self.hidesBottomBarWhenPushed = true
        self.title = thread.cachedContactIdentifier

        self.registerNotifications()

        self.additionalContentInsets.top = 48
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: View life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.messageViewBackgroundColor
        self.containerView?.backgroundColor = nil

        self.view.addSubview(self.ethereumPromptView)
        self.ethereumPromptView.heightAnchor.constraint(equalToConstant: ChatsFloatingHeaderView.height).isActive = true
        self.ethereumPromptView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.ethereumPromptView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.ethereumPromptView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.collectionView.keyboardDismissMode = .interactive
        self.collectionView.backgroundColor = nil

        self.navigationItem.rightBarButtonItem = self.rateButton

        self.fetchAndUpdateBalance()
        self.loadMessages()

        self.view.addSubview(self.textInputView)

        NSLayoutConstraint.activate([
            self.textInputView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.textInputView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            textInputViewBottom,
            textInputViewHeight,
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadDraft()
        self.view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
        self.title = self.thread.cachedContactIdentifier
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.saveDraft()

        self.thread.markAllAsRead()
        SignalNotificationManager.updateApplicationBadgeNumber()
    }

    func fetchAndUpdateBalance() {
        self.ethereumAPIClient.getBalance(address: Cereal.shared.paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.set(balance: balance)
            }
        }
    }

    func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.set(balance: balance)
    }

    func set(balance: NSDecimalNumber) {
        self.ethereumPromptView.balance = balance
    }

    func saveDraft() {
        let thread = self.thread
        guard let text = self.textInputView.text else { return }

        self.editingDatabaseConnection.asyncReadWrite { transaction in
            thread.setDraft(text, transaction: transaction)
        }
    }

    func reloadDraft() {
        let thread = self.thread
        var placeholder: String?

        self.editingDatabaseConnection.asyncReadWrite({ transaction in
            placeholder = thread.currentDraft(with: transaction)
        }, completionBlock: {
            DispatchQueue.main.async {
                self.textInputView.text = placeholder
            }
        })
    }

    override func registerChatItemCells() {
        self.collectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.reuseIdentifier())
        self.collectionView.register(ActionableMessageCell.self, forCellWithReuseIdentifier: ActionableMessageCell.reuseIdentifier())
        self.collectionView.register(ImageMessageCell.self, forCellWithReuseIdentifier: ImageMessageCell.reuseIdentifier())
    }

    // MARK: Rate users
    func didTapRateUser() {
        let contactId = self.thread.contactIdentifier()!
        let contact = self.contactsManager.tokenContact(forAddress: contactId)

        if let contact = contact {
            self.presentUserRatingPrompt(contact: contact)
        } else {
            self.idAPIClient.findContact(name: contactId) { contact in
                guard let contact = contact else { return }
                self.presentUserRatingPrompt(contact: contact)
            }
        }
    }

    func presentUserRatingPrompt(contact: TokenContact) {
        let rateUserController = RateUserController(user: contact)
        rateUserController.delegate = self

        self.present(rateUserController, animated: true)
    }

    // MARK: Load initial messages

    func loadMessages() {
        self.uiDatabaseConnection.asyncRead { transaction in
            self.mappings.update(with: transaction)

            var messages = [Message]()

            for i in 0 ..< self.mappings.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(row: Int(i), section: 0)
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }
                guard let interaction = dbExtension.object(at: indexPath, with: self.mappings) as? TSInteraction else { fatalError() }

                DispatchQueue.main.async {
                    var shouldProcess = false
                    if let message = interaction as? TSMessage, SofaType(sofa: message.body ?? "") == .paymentRequest {
                        shouldProcess = true
                    }

                    messages.append(self.handleInteraction(interaction, shouldProcessCommands: shouldProcess))
                }
            }

            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.messages = messages
                    self.collectionView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            }
        }
    }

    // Mark: Handle new messages

    func showFingerprint(with _: Data, signalId _: String) {
        // Postpone this for now
        print("Should display fingerprint comparison UI.")
        //        let builder = OWSFingerprintBuilder(storageManager: self.storageManager, contactsManager: self.contactsManager)
        //        let fingerprint = builder.fingerprint(withTheirSignalId: signalId, theirIdentityKey: identityKey)
        //
        //        let fingerprintController = FingerprintViewController(fingerprint: fingerprint)
        //        self.present(fingerprintController, animated: true)
    }

    func handleInvalidKeyError(_ errorMessage: TSInvalidIdentityKeyErrorMessage) {
        let keyOwner = self.contactsManager.displayName(forPhoneIdentifier: errorMessage.theirSignalId())
        let titleText = "Your safety number with \(keyOwner) has changed. You may wish to verify it."

        let actionSheetController = UIAlertController(title: titleText, message: nil, preferredStyle: .actionSheet)

        let dismissAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheetController.addAction(dismissAction)

        let showSafteyNumberAction = UIAlertAction(title: NSLocalizedString("Compare fingerprints.", comment: "Action sheet item"), style: .default) { (_: UIAlertAction) -> Void in

            self.showFingerprint(with: errorMessage.newIdentityKey(), signalId: errorMessage.theirSignalId())
        }
        actionSheetController.addAction(showSafteyNumberAction)

        let acceptSafetyNumberAction = UIAlertAction(title: NSLocalizedString("Accept the new contact identity.", comment: "Action sheet item"), style: .default) { (_: UIAlertAction) -> Void in

            errorMessage.acceptNewIdentityKey()
            if errorMessage is TSInvalidIdentityKeySendingErrorMessage {
                self.messageSender.resendMessage(fromKeyError: (errorMessage as! TSInvalidIdentityKeySendingErrorMessage), success: { () -> Void in
                    print("Got it!")
                }, failure: { (_ error: Error) -> Void in
                    print(error)
                })
            }
        }
        actionSheetController.addAction(acceptSafetyNumberAction)

        present(actionSheetController, animated: true, completion: nil)
    }

    /// Handle incoming interactions or previous messages when restoring a conversation.
    ///
    /// - Parameters:
    ///   - interaction: the interaction to handle. Incoming/outgoing messages, wrapping SOFA structures.
    ///   - shouldProcessCommands: If true, will process a sofa wrapper. This means replying to requests, displaying payment UI etc.
    ///
    func handleInteraction(_ interaction: TSInteraction, shouldProcessCommands: Bool = false) -> Message {
        if let interaction = interaction as? TSInvalidIdentityKeySendingErrorMessage {
            DispatchQueue.main.async {
                self.handleInvalidKeyError(interaction)
            }

            return Message(sofaWrapper: nil, signalMessage: interaction, date: interaction.date(), isOutgoing: false)
        }

        if let message = interaction as? TSMessage, shouldProcessCommands {
            let type = SofaType(sofa: message.body)
            switch type {
            case .metadataRequest:
                let metadataResponse = SofaMetadataResponse(metadataRequest: SofaMetadataRequest(content: message.body!))
                self.sendMessage(sofaWrapper: metadataResponse)
            default:
                break
            }
        }

        /// TODO: Simplify how we deal with interactions vs text messages.
        /// Since now we know we can expande the TSInteraction stored properties, maybe we can merge some of this together.
        if let interaction = interaction as? TSOutgoingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body!)
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.date(), isOutgoing: true)

            if interaction.hasAttachments() {
                message.messageType = "Image"
            } else if let payment = SofaWrapper.wrapper(content: interaction.body ?? "") as? SofaPayment {
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: "Payment sent", attributes: [NSForegroundColorAttributeName: Theme.outgoingMessageTextColor, NSFontAttributeName: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value).string, attributes: [NSForegroundColorAttributeName: Theme.outgoingMessageTextColor, NSFontAttributeName: Theme.regular(size: 15)])
            }

            return message
        } else if let interaction = interaction as? TSIncomingMessage {
            let sofaWrapper = SofaWrapper.wrapper(content: interaction.body!)
            let message = Message(sofaWrapper: sofaWrapper, signalMessage: interaction, date: interaction.date(), isOutgoing: false, shouldProcess: shouldProcessCommands && interaction.paymentState == .none)

            if interaction.hasAttachments() {
                message.messageType = "Image"
            } else if let sofaMessage = sofaWrapper as? SofaMessage {
                buttons = sofaMessage.buttons
            } else if let paymentRequest = sofaWrapper as? SofaPaymentRequest {
                message.messageType = "Actionable"
                message.title = "Payment request"
                message.attributedSubtitle = EthereumConverter.balanceAttributedString(forWei: paymentRequest.value)
            } else if let payment = sofaWrapper as? SofaPayment {
                message.messageType = "Actionable"
                message.attributedTitle = NSAttributedString(string: "Payment received", attributes: [NSForegroundColorAttributeName: Theme.incomingMessageTextColor, NSFontAttributeName: Theme.medium(size: 17)])
                message.attributedSubtitle = NSAttributedString(string: EthereumConverter.balanceAttributedString(forWei: payment.value).string, attributes: [NSForegroundColorAttributeName: Theme.incomingMessageTextColor, NSFontAttributeName: Theme.regular(size: 15)])
            }

            return message
        } else {
            return Message(sofaWrapper: nil, signalMessage: interaction as! TSMessage, date: interaction.date(), isOutgoing: false)
        }
    }

    // MARK: Add displayable messages

    private func addMessages(_ messages: [Message], scrollToBottom: Bool) {
        self.textLayoutQueue.async {
            let indexes = IndexSet(integersIn: 0 ..< messages.count)

            DispatchQueue.main.async {
                var layouts = [NOCChatItemCellLayout]()

                for message in messages {
                    let layout = self.createLayout(with: message)!
                    layouts.append(layout)
                }

                if !layouts.isEmpty {
                    self.insertLayouts(layouts.reversed(), at: indexes, animated: true)
                }
                if scrollToBottom {
                    self.scrollToBottom(animated: true)
                }
            }
        }
    }

    // MARK: - Helper methods

    func visibleMessage(at indexPath: IndexPath) -> Message {
        return self.visibleMessages[indexPath.row]
    }

    func message(at indexPath: IndexPath) -> Message {
        return self.messages[indexPath.row]
    }

    func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)
    }

    func reversedIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row = (self.visibleMessages.count - 1) - indexPath.item
        return IndexPath(row: row, section: indexPath.section)
    }

    // MARK: Handle database changes

    func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = self.uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // TODO: Since this is used in more than one place, we should look into abstracting this away, into our own
        // table/collection view backing model.
        let viewConnection = self.uiDatabaseConnection.ext(TSMessageDatabaseViewExtensionName) as! YapDatabaseViewConnection
        let hasChangesForCurrentView = viewConnection.hasChanges(for: notifications)
        if !hasChangesForCurrentView {
            self.uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        // HACK to work around radar #28167779
        // "UICollectionView performBatchUpdates can trigger a crash if the collection view is flagged for layout"
        // more: https://github.com/PSPDFKit-labs/radar.apple.com/tree/master/28167779%20-%20CollectionViewBatchingIssue
        // This was our #2 crash, and much exacerbated by the refactoring somewhere between 2.6.2.0-2.6.3.8
        self.collectionView.layoutIfNeeded() // ENDHACK to work around radar #28167779

        var messageRowChanges = NSArray()
        var sectionChanges = NSArray()

        viewConnection.getSectionChanges(&sectionChanges, rowChanges: &messageRowChanges, for: notifications, with: self.mappings)

        if messageRowChanges.count == 0 {
            return
        }

        self.uiDatabaseConnection.asyncRead { transaction in
            for change in messageRowChanges as! [YapDatabaseViewRowChange] {
                guard let dbExtension = transaction.ext(TSMessageDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { fatalError() }

                switch change.type {
                case .insert:
                    guard let interaction = dbExtension.object(at: change.newIndexPath, with: self.mappings) as? TSInteraction else { fatalError("woot") }

                    DispatchQueue.main.async {
                        let result = self.handleInteraction(interaction, shouldProcessCommands: true)
                        self.messages.append(result)

                        if result.isOutgoing {
                            if result.sofaWrapper?.type == .paymentRequest {
                                SoundPlayer.playSound(type: .requestPayment)
                            } else if result.sofaWrapper?.type == .payment {
                                SoundPlayer.playSound(type: .paymentSend)
                            } else {
                                SoundPlayer.playSound(type: .messageSent)
                            }
                        } else {
                            SoundPlayer.playSound(type: .messageReceived)
                        }

                        if let incoming = interaction as? TSIncomingMessage, !incoming.wasRead {
                            incoming.markAsReadLocally()
                        }
                    }
                case .update:
                    let indexPath = change.indexPath
                    guard let interaction = dbExtension.object(at: indexPath, with: self.mappings) as? TSMessage else { return }

                    DispatchQueue.main.async {
                        guard self.visibleMessages.count == self.layouts.count else {
                            print("Called before colection view had a chance to insert message.")

                            return
                        }

                        let message = self.message(at: indexPath)
                        guard let visibleIndex = self.visibleMessages.index(of: message) else { return }
                        let reversedIndex = self.reversedIndexPath(IndexPath(row: visibleIndex, section: 0)).row
                        guard let layout = self.layouts[reversedIndex] as? MessageCellLayout else { return }

                        if let signalMessage = layout.message.signalMessage as? TSOutgoingMessage, let newSignalMessage = interaction as? TSOutgoingMessage {
                            signalMessage.messageState = newSignalMessage.messageState
                        }

                        layout.calculate()

                        self.updateLayout(at: UInt(reversedIndex), to: layout, animated: true)
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: Send messages

    func sendMessage(sofaWrapper: SofaWrapper, date: Date = Date()) {
        let timestamp = NSDate.ows_millisecondsSince1970(for: date)
        let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: sofaWrapper.content)

        self.messageSender.send(outgoingMessage, success: {
            print("message sent")
        }, failure: { error in
            print(error)
        })
    }

    // MARK: - Collection view overrides

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)

        if let cell = cell as? ActionableMessageCell {
            cell.actionsDelegate = self
        }

        return cell
    }

    // MARK: - Control handling

    override func didTapControlButton(_ button: SofaMessage.Button) {
        guard button.value != nil else {
            print("Implement handling actions. action: \(button.action ?? "nil")")

            return
        }

        // clear the buttons
        self.buttons = []
        let command = SofaCommand(button: button)
        self.controlsViewDelegateDatasource.controlsCollectionView?.isUserInteractionEnabled = false
        self.sendMessage(sofaWrapper: command)
    }
}

extension ChatController: ActionableCellDelegate {

    func didTapRejectButton(_ messageCell: ActionableMessageCell) {
        guard let indexPath = self.collectionView.indexPath(for: messageCell) else { return }
        let visibleMessageIndexPath = reversedIndexPath(indexPath)

        let message = visibleMessage(at: visibleMessageIndexPath)
        message.isActionable = false

        let layout = self.layouts[indexPath.item] as? MessageCellLayout
        layout?.chatItem = message
        layout?.calculate()

        let interaction = message.signalMessage
        interaction.paymentState = .rejected
        interaction.save()
    }

    func didTapApproveButton(_ messageCell: ActionableMessageCell) {
        guard let indexPath = self.collectionView.indexPath(for: messageCell) else { return }
        let visibleMessageIndexPath = reversedIndexPath(indexPath)

        let message = visibleMessage(at: visibleMessageIndexPath)
        message.isActionable = false

        let layout = self.layouts[indexPath.item] as? MessageCellLayout
        layout?.chatItem = message
        layout?.calculate()

        let interaction = message.signalMessage
        interaction.paymentState = .pendingConfirmation
        interaction.save()

        guard let paymentRequest = message.sofaWrapper as? SofaPaymentRequest else { fatalError("Could not retrieve payment request for approval.") }

        let value = paymentRequest.value
        guard let destination = paymentRequest.destinationAddress else { return }

        // TODO: prevent concurrent calls
        // Also, extract this.
        self.etherAPIClient.createUnsignedTransaction(to: destination, value: value) { transaction, error in
            let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction!))"

            self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction!, transactionSignature: signedTransaction) { json, error in
                if error != nil {
                    guard let json = json?.dictionary else { fatalError("!") }

                    let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: json["message"] as? String)
                    self.present(alert, animated: true)
                } else if let json = json?.dictionary {
                    // update payment request message
                    message.isActionable = false

                    let interaction = message.signalMessage
                    interaction.paymentState = .pendingConfirmation
                    interaction.save()

                    // send payment message
                    guard let txHash = json["tx_hash"] as? String else { fatalError("Error recovering transaction hash.") }
                    let payment = SofaPayment(txHash: txHash, valueHex: value.toHexString)

                    self.sendMessage(sofaWrapper: payment)
                }
            }
        }
    }
}

extension ChatController: ChatInputTextPanelDelegate {

    func inputTextPanel(_: ChatInputTextPanel, requestSendText text: String) {
        let wrapper = SofaMessage(content: ["body": text])
        sendMessage(sofaWrapper: wrapper)
    }

    func inputTextPanelrequestSendAttachment(_: ChatInputTextPanel) {
        let picker = ImagePickerController()
        picker.delegate = self

        self.present(picker, animated: true)
    }

    func inputTextPanelDidChangeHeight(_ height: CGFloat) {
        self.textInputHeight = height
    }
}

extension ChatController: RateUserControllerDelegate {
    func didRate(_ user: TokenContact, rating: Int, review: String) {
        self.dismiss(animated: true) {
            let ratingsClient = RatingsClient.shared
            ratingsClient.submit(userId: user.address, rating: rating, review: review)
        }
    }
}

extension ChatController: ImagePickerDelegate {
    func wrapperDidPress(_: ImagePickerController, images _: [UIImage]) {
        print("ok")
    }

    func doneButtonDidPress(_: ImagePickerController, images: [UIImage]) {
        self.dismiss(animated: true) {
            for image in images {
                guard let imageData = UIImageJPEGRepresentation(image, 0.6) else { return }

                let timestamp = NSDate.ows_millisecondsSince1970(for: Date())
                let outgoingMessage = TSOutgoingMessage(timestamp: timestamp, in: self.thread, messageBody: "")

                self.messageSender.sendAttachmentData(imageData, contentType: "image/jpeg" as String, in: outgoingMessage, success: {
                    print("Success")
                }, failure: { error in
                    print("Failure: \(error)")
                })
            }
        }
    }

    func cancelButtonDidPress(_: ImagePickerController) {
        self.dismiss(animated: true)
    }
}

extension ChatController: ChatsFloatingHeaderViewDelegate {

    func messagesFloatingView(_: ChatsFloatingHeaderView, didPressRequestButton _: UIButton) {
        let paymentRequestController = PaymentRequestController()
        paymentRequestController.delegate = self

        present(paymentRequestController, animated: true)
    }

    func messagesFloatingView(_: ChatsFloatingHeaderView, didPressPayButton _: UIButton) {
        let paymentSendController = PaymentSendController()
        paymentSendController.delegate = self

        present(paymentSendController, animated: true)
    }
}

extension ChatController: PaymentSendControllerDelegate {

    func paymentSendControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let value = valueInWei else {
            return
        }

        // TODO: prevent concurrent calls
        // Also, extract this.
        guard let tokenId = self.thread.contactIdentifier() else {
            return
        }

        self.idAPIClient.retrieveContact(username: tokenId) { user in
            if let user = user {
                self.etherAPIClient.createUnsignedTransaction(to: user.paymentAddress, value: value) { transaction, error in
                    let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction!))"

                    self.etherAPIClient.sendSignedTransaction(originalTransaction: transaction!, transactionSignature: signedTransaction) { json, error in
                        if error != nil {
                            guard let json = json?.dictionary else { fatalError("!") }

                            let alert = UIAlertController.dismissableAlert(title: "Error completing transaction", message: json["message"] as? String)
                            self.present(alert, animated: true)
                        } else if let json = json?.dictionary {
                            guard let txHash = json["tx_hash"] as? String else { fatalError("Error recovering transaction hash.") }
                            let payment = SofaPayment(txHash: txHash, valueHex: value.toHexString)
                            self.sendMessage(sofaWrapper: payment)
                        }
                    }
                }
            }
        }
    }
}

extension ChatController: PaymentRequestControllerDelegate {

    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?) {
        defer {
            self.dismiss(animated: true)
        }

        guard let valueInWei = valueInWei else {
            return
        }

        let request: [String: Any] = [
            "body": "Payment request: \(EthereumConverter.balanceAttributedString(forWei: valueInWei).string).",
            "value": valueInWei.toHexString,
            "destinationAddress": Cereal.shared.paymentAddress,
        ]

        let paymentRequest = SofaPaymentRequest(content: request)

        sendMessage(sofaWrapper: paymentRequest)
    }
}
