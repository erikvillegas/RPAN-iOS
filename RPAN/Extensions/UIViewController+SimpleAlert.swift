//
//  UIViewController+SimpleAlert.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

extension UIViewController {
    /// Presents simple alert with "OK" button
    /// Pass in a non-nil `onceToken` to only present this alert once. If already presented, `okHandler` is fired immediately.
    func showSimpleAlert(title: String, message: String, okTitle: String = "OK", onceToken: String? = nil, okHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: okTitle, style: .default, handler: okHandler))

        if let onceToken = onceToken {
            guard !UserDefaults.standard.bool(forKey: onceToken) else {
                okHandler?(UIAlertAction())
                return
            }

            UserDefaults.standard.set(true, forKey: onceToken)
        }

        self.present(alertController, animated: true, completion: nil)
    }

    /// Presents simple alert with "Yes" and "No" buttons
    func showYesNoAlert(title: String, message: String?, yesHandler: @escaping ((UIAlertAction) -> Void), noHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .default, handler: noHandler))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: yesHandler))
        self.present(alertController, animated: true, completion: nil)
    }

    /// Presents an alert with a custom action such as "Confirm".
    func showCustomActionAlert(title: String, message: String, actionTitle: String, actionHandler: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))
        alertController.preferredAction = alertController.actions.last
        self.present(alertController, animated: true, completion: nil)
    }

    /// Presents an alert with a custom action such as "Confirm".
    func showCustomActionsAlert(title: String,
                                message: String,
                                actionTitle: String,
                                cancelTitle: String,
                                actionHandler: @escaping ((UIAlertAction) -> Void),
                                cancelHandler: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .default, handler: cancelHandler))
        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: actionHandler))
        alertController.preferredAction = alertController.actions.last
        self.present(alertController, animated: true, completion: nil)
    }

    /// Presents an alert with a destructive action such as "Delete".
    func showDestructiveAlert(title: String, message: String?, destructiveTitle: String, cancelTitle: String = "Cancel", actionHandler: @escaping ((UIAlertAction) -> Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive, handler: actionHandler))
        self.present(alertController, animated: true, completion: nil)
    }

    func showSimpleInputCollection(title: String,
                                   okTitle: String = "Done",
                                   cancelTitle: String = "Cancel",
                                   message: String? = nil,
                                   startingValue: String? = nil,
                                   keyboardType: UIKeyboardType = .alphabet,
                                   completion: @escaping (String) -> Void,
                                   cancel: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in
            cancel?()
        }))
        alert.addAction(UIAlertAction(title: okTitle, style: .default, handler: { _ in
            completion(alert.textFields?.first?.text ?? "")
        }))

        alert.addTextField { textField in
            textField.textAlignment = .center
            textField.autocorrectionType = .no
            textField.keyboardType = keyboardType
            textField.text = startingValue
        }

        self.present(alert, animated: true, completion: nil)
    }
}
