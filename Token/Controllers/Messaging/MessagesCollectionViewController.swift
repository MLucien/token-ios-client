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

class MessagesCollectionViewController: NOCChatViewController {

    enum DisplayState {
        case hide
        case show
        case hideAndShow
        case doNothing
    }

    lazy var textInputViewBottom: NSLayoutConstraint = {
        self.textInputView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    }()

    lazy var textInputView: ChatInputTextPanel = {
        let view = ChatInputTextPanel(withAutoLayout: true)
        view.delegate = self

        return view
    }()

    lazy var textInputViewHeight: NSLayoutConstraint = {
        self.textInputView.heightAnchor.constraint(equalToConstant: ChatInputTextPanel.defaultHeight)
    }()

    var textInputHeight: CGFloat = ChatInputTextPanel.defaultHeight {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

    let buttonMargin: CGFloat = 10

    var buttonsHeight: CGFloat = 0 {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

    var heightOfKeyboard: CGFloat = 0 {
        didSet {
            if self.isVisible {
                self.updateConstraints()
            }
        }
    }

    func updateConstraints() {
        self.controlsViewBottomConstraint.constant = min(-self.textInputHeight - self.buttonMargin, self.heightOfKeyboard + self.buttonsHeight - self.buttonMargin)
        self.textInputViewBottom.constant = self.heightOfKeyboard < -self.textInputHeight ? self.heightOfKeyboard + self.textInputHeight + self.buttonsHeight : 0

        self.textInputViewHeight.constant = self.textInputHeight

        self.controlsViewHeightConstraint.constant = self.buttonsHeight
        self.keyboardAwareInputView.height = self.buttonsHeight + self.textInputHeight

        self.keyboardAwareInputView.invalidateIntrinsicContentSize()
        self.view.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isVisible = true
        self.view.layoutIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isVisible = false
        self.heightOfKeyboard = 0
    }

    private var isVisible: Bool = false

    var buttons: [SofaMessage.Button] = [] {
        didSet {
            // Ensure we're dealing with layout inside the main queue.
            DispatchQueue.main.async {
                self.controlsView.isHidden = true
                self.updateSubcontrols(with: nil)
                self.controlsViewHeightConstraint.constant = 500
                self.controlsViewDelegateDatasource.items = self.buttons
                self.controlsView.reloadData()
                self.view.layoutIfNeeded()

                // Re-enqueues this back to the main queue to ensure the collection view
                // has filled in its cells. Thanks UIKit.
                DispatchQueue.main.asyncAfter(seconds: 0.5) {
                    var height: CGFloat = 0

                    self.controlsViewHeightConstraint.constant = 500
                    self.controlsView.reloadData()
                    self.view.layoutIfNeeded()

                    let controlCells = self.controlsView.visibleCells.flatMap { cell in cell as? ControlCell }

                    for controlCell in controlCells {
                        controlCell.transform = CGAffineTransform(scaleX: -1, y: -1)
                        height = max(height, controlCell.frame.maxY)
                    }

                    self.buttonsHeight = height > 0 ? height + (2 * self.buttonMargin) : 0

                    self.controlsView.isHidden = false
                    self.controlsView.deselectButtons()

                    self.view.layoutIfNeeded()

                    self.scrollToBottom(animated: true)
                }
            }
        }
    }

    lazy var controlsViewDelegateDatasource: ControlsViewDelegateDatasource = {
        let controlsViewDelegateDatasource = ControlsViewDelegateDatasource()
        controlsViewDelegateDatasource.actionDelegate = self

        return controlsViewDelegateDatasource
    }()

    lazy var subcontrolsViewDelegateDatasource: SubcontrolsViewDelegateDatasource = {
        let subcontrolsViewDelegateDatasource = SubcontrolsViewDelegateDatasource()
        subcontrolsViewDelegateDatasource.actionDelegate = self

        return subcontrolsViewDelegateDatasource
    }()

    lazy var controlsViewBottomConstraint: NSLayoutConstraint = {
        self.controlsView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
    }()

    lazy var controlsViewHeightConstraint: NSLayoutConstraint = {
        self.controlsView.heightAnchor.constraint(equalToConstant: 0)
    }()

    lazy var subcontrolsViewHeightConstraint: NSLayoutConstraint = {
        self.subcontrolsView.heightAnchor.constraint(equalToConstant: 0)
    }()

    lazy var subcontrolsViewWidthConstraint: NSLayoutConstraint = {
        self.subcontrolsView.widthAnchor.constraint(equalToConstant: self.view.frame.width)
    }()

    lazy var controlsView: ControlsCollectionView = {
        let view = ControlsCollectionView()

        view.clipsToBounds = true

        // Upside down collection views!
        view.transform = CGAffineTransform(scaleX: -1, y: -1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(ControlCell.self)
        view.delegate = self.controlsViewDelegateDatasource
        view.dataSource = self.controlsViewDelegateDatasource

        return view
    }()

    lazy var subcontrolsView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = Theme.borderHeight

        // Upside down collection views!
        view.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(SubcontrolCell.self)
        view.delegate = self.subcontrolsViewDelegateDatasource
        view.dataSource = self.subcontrolsViewDelegateDatasource

        return view
    }()

    var currentButton: SofaMessage.Button?

    override static func inputPanelClass() -> AnyClass? {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.controlsView)
        self.view.addSubview(self.subcontrolsView)

        // menus
        self.subcontrolsViewHeightConstraint.isActive = true
        self.subcontrolsViewWidthConstraint.isActive = true
        self.subcontrolsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.subcontrolsView.bottomAnchor.constraint(equalTo: self.controlsView.topAnchor, constant: self.buttonMargin).isActive = true

        self.subcontrolsViewDelegateDatasource.subcontrolsCollectionView = self.subcontrolsView

        // buttons
        self.controlsViewHeightConstraint.isActive = true
        self.controlsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.controlsView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true

        self.controlsViewBottomConstraint.isActive = true

        self.controlsViewDelegateDatasource.controlsCollectionView = self.controlsView

        self.hideSubcontrolsMenu()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
    }

    func keyboardDidHide() {
        self.becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController == nil
    }

    func didTapControlButton(_: SofaMessage.Button) {
        // to be implemented by subclass
    }

    // TODO: simplify and better document?
    // also more testing.
    func displayState(for button: SofaMessage.Button?) -> DisplayState {
        if let button = button, let currentButton = self.currentButton {
            if button == currentButton {
                return .hide
            } else {
                return .hideAndShow
            }
        }

        if button == nil && self.currentButton == nil {
            return .doNothing
        } else if button == nil && self.currentButton != nil {
            return .hide
        } else { //  if button != nil && self.currentButton == nil
            return .show
        }
    }
}

extension MessagesCollectionViewController: KeyboardAwareAccessoryViewDelegate {

    func inputView(_: KeyboardAwareInputAccessoryView, shouldUpdatePosition keyboardOriginYDistance: CGFloat) {
        self.heightOfKeyboard = keyboardOriginYDistance
    }

    override var inputAccessoryView: UIView? {
        self.keyboardAwareInputView.isUserInteractionEnabled = false
        return self.keyboardAwareInputView
    }
}

extension MessagesCollectionViewController: ControlViewActionDelegate {

    func controlsCollectionViewDidSelectControl(_ button: SofaMessage.Button) {
        switch button.type {
        case .button:
            self.didTapControlButton(button)
        case .group:
            self.updateSubcontrols(with: button)
        }
    }

    func updateSubcontrols(with button: SofaMessage.Button?) {
        switch self.displayState(for: button) {
        case .show:
            self.showSubcontrolsMenu(button: button!)
        case .hide:
            self.hideSubcontrolsMenu()
        case .hideAndShow:
            self.hideSubcontrolsMenu {
                self.showSubcontrolsMenu(button: button!)
            }
        case .doNothing:
            break
        }
    }

    func hideSubcontrolsMenu(completion: (() -> Void)? = nil) {
        self.subcontrolsViewDelegateDatasource.items = []
        self.currentButton = nil

        self.subcontrolsViewHeightConstraint.constant = 0
        self.subcontrolsView.backgroundColor = .clear
        self.subcontrolsView.isHidden = true

        self.controlsView.deselectButtons()

        self.view.layoutIfNeeded()

        completion?()
    }

    func showSubcontrolsMenu(button: SofaMessage.Button, completion: (() -> Void)? = nil) {
        self.controlsView.deselectButtons()
        // ensure we have enough height to fill in all the views
        self.subcontrolsViewHeightConstraint.constant = self.view.frame.height
        // ensure we won't be flashing unfinished content
        self.subcontrolsView.isHidden = true

        let controlCell = SubcontrolCell(frame: .zero)
        var maxWidth: CGFloat = 0.0

        // gets width of widest cell
        button.subcontrols.forEach { button in
            controlCell.button.setTitle(button.label, for: .normal)
            let bounds = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 38)
            maxWidth = max(maxWidth, controlCell.button.titleLabel!.textRect(forBounds: bounds, limitedToNumberOfLines: 1).width + controlCell.buttonInsets.left + controlCell.buttonInsets.right)
        }

        // reverse the order of the buttons because the collection view is upside-down
        self.subcontrolsViewDelegateDatasource.items = button.subcontrols.reversed()
        // adds some margins
        self.subcontrolsViewWidthConstraint.constant = maxWidth

        self.currentButton = button

        self.subcontrolsView.reloadData()

        // Re-enqueues this back to the main queue to ensure the collection view
        // has filled in its cells. Thanks UIKit.
        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            var height: CGFloat = 0

            // calculates the new menu height
            for cell in self.subcontrolsView.visibleCells {
                height += cell.frame.height
                cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            }

            self.subcontrolsViewHeightConstraint.constant = height
            self.subcontrolsView.isHidden = false
            self.view.layoutIfNeeded()

            completion?()
        }
    }
}
