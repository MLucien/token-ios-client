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

class BackupPhraseCopyController: UIViewController {

    let idAPIClient: IDAPIClient

    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel("This is your backup phrase")

        return view
    }()

    lazy var textLabel: UILabel = {
        let view = TextLabel("Carefully write down the words.\nDon’t email it or screenshot it..")
        view.textAlignment = .center

        return view
    }()

    private lazy var actionButton: ActionButton = {
        let view = ActionButton(margin: 30)
        view.title = "Verify phrase"
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)

        return view
    }()

    private lazy var phraseView: BackupPhraseView = {
        let view = BackupPhraseView(with: Cereal().mnemonic.words, for: .original)

        return view
    }()

    private lazy var confirmationButton: ConfirmationButton = {
        let view = ConfirmationButton(withAutoLayout: true)
        view.title = "Copy phrase to clipboard"
        view.confirmation = "Copied to clipboard"
        view.addTarget(self, action: #selector(copyToClipBoard(_:)), for: .touchUpInside)

        return view
    }()

    private init() {
        fatalError()
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    public init(idAPIClient: IDAPIClient) {
        self.idAPIClient = idAPIClient

        super.init(nibName: nil, bundle: nil)
        self.title = "Store backup phrase"
        self.hidesBottomBarWhenPushed = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Theme.settingsBackgroundColor

        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.textLabel)
        self.view.addSubview(self.phraseView)
        self.view.addSubview(self.confirmationButton)
        self.view.addSubview(self.actionButton)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40 + 64),
            self.titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.textLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),

            self.phraseView.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 60),
            self.phraseView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15),
            self.phraseView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15),

            self.confirmationButton.topAnchor.constraint(equalTo: self.phraseView.bottomAnchor, constant: 20),
            self.confirmationButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),

            self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.actionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        self.navigationItem.backBarButtonItem = backItem
    }

    func proceed(_: ActionButton) {
        let controller = BackupPhraseVerifyController(idAPIClient: self.idAPIClient)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func copyToClipBoard(_ button: ConfirmationButton) {

        UIPasteboard.general.string = Cereal().mnemonic.words.joined(separator: " ")

        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            button.contentState = button.contentState == .actionable ? .confirmation : .actionable
        }
    }
}
