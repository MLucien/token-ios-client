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

public extension NSNotification.Name {
    public static let UserDidSignOut = NSNotification.Name(rawValue: "UserDidSignOut")
}

open class SettingsController: SweetTableController {

    public static let verificationStatusChanged = Notification.Name(rawValue: "VerificationStatusChanged")

    private var verificationStatus: VerificationStatus = .unverified

    public var chatAPIClient: ChatAPIClient
    public var idAPIClient: IDAPIClient

    let numberOfSections = 3
    let numberOfRows = [1, 1, 1]
    let cellTypes: [BaseCell.Type] = [ProfileCell.self, SecurityCell.self, SettingsCell.self]
    let sectionTitles = ["Your profile", "Security", "Settings"]
    let sectionErrors = [nil, "Your account is at risk", nil]

    let securityTitles = ["Store backup phrase" /* , "Choose trusted friends" */ ]
    let settingsTitles = [ /* "Local currency", "About", "Sign in on another device", */ "Sign out"]

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public init(idAPIClient: IDAPIClient, chatAPIClient: ChatAPIClient) {
        self.idAPIClient = idAPIClient
        self.chatAPIClient = chatAPIClient

        super.init(style: .grouped)
        self.title = "Me"

        NotificationCenter.default.addObserver(self, selector: #selector(self.updateVerificationStatus(_:)), name: SettingsController.verificationStatusChanged, object: nil)
    }

    func updateVerificationStatus(_ notification: Notification) {
        if let verificationStatus = notification.object as? VerificationStatus {
            self.verificationStatus = verificationStatus
        }
    }

    var didVerifyBackupPhrase: Bool {
        return self.verificationStatus == .correct
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.backgroundColor = Theme.settingsBackgroundColor
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

        for type in self.cellTypes {
            self.tableView.register(type)
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()

        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        self.navigationItem.backBarButtonItem = backItem
    }

    func handleSignOut() {
        guard let currentUser = User.current else {
            let alert = UIAlertController(title: "No user found!", message: "This is an error. Please report this.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                fatalError()
            }))
            self.present(alert, animated: true)

            return
        }

        let alert = self.alertController(verificationStatus: self.verificationStatus, balance: currentUser.balance)
        // We dispatch it back to the main thread here, even tho we are already inside the main thread
        // to avoid some weird issue where the alert controller will take seconds to present, instead of being instant.
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    func alertController(verificationStatus status: VerificationStatus, balance: NSDecimalNumber) -> UIAlertController {
        var alert: UIAlertController

        if status == .correct {
            alert = UIAlertController(title: "Have you secured your backup phrase?", message: "Without this you will not be able to recover your account or sign back in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Sign out", style: .destructive) { _ in
                NotificationCenter.default.post(name: .UserDidSignOut, object: nil)
            })
        } else if balance == .zero {
            alert = UIAlertController(title: "Are you sure you want to sign out?", message: "Since you have no funds and did not secure your account, it will be deleted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                NotificationCenter.default.post(name: .UserDidSignOut, object: nil)
            })
        } else {
            alert = UIAlertController(title: "Sign out cancelled", message: "You need to complete at least one of the security steps to sign out.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        }

        return alert
    }
}

extension SettingsController: UITableViewDataSource {

    open func numberOfSections(in _: UITableView) -> Int {
        return self.numberOfSections
    }

    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows[section]
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeue(cellTypes[indexPath.section], for: indexPath)
    }

    open func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = SettingsSectionHeader(title: sectionTitles[section], error: sectionErrors[section])
        view.setErrorHidden(self.didVerifyBackupPhrase, animated: false)

        return view
    }

    open func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 25
    }
}

extension SettingsController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        if let cell = cell as? BaseCell {
            cell.selectionStyle = .none
            cell.setIndex(indexPath.row, from: tableView.numberOfRows(inSection: indexPath.section))
        }

        if let cell = cell as? ProfileCell {
            cell.user = User.current
        } else if let cell = cell as? SecurityCell {
            cell.title = securityTitles[indexPath.row]

            if indexPath.row == 0 {
                DispatchQueue.main.asyncAfter(seconds: 0.5) {

                    if self.didVerifyBackupPhrase == true, cell.checkbox.checked == false {
                        cell.checkbox.bounce()
                    }

                    cell.checkbox.checked = self.didVerifyBackupPhrase
                }
            }
        } else if let cell = cell as? SettingsCell {
            cell.title = settingsTitles[indexPath.row]
        }
    }

    public func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0, indexPath.row == 0 {
            self.navigationController?.pushViewController(ProfileController(idAPIClient: self.idAPIClient), animated: true)
        } else if indexPath.section == 1, indexPath.row == 0 {
            self.navigationController?.pushViewController(BackupPhraseEnableController(idAPIClient: self.idAPIClient), animated: true)
        } else if let cell = tableView.cellForRow(at: indexPath) as? SecurityCell {
            cell.checkbox.checked = !cell.checkbox.checked
        } else if indexPath.section == 2, indexPath.row == 0 {
            self.handleSignOut()
        }
    }
}
