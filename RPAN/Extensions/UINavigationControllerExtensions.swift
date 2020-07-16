//
//  UINavigationControllerExtensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

extension UINavigationController {
    /// Replaces the top controller with the provided controller with no animations
    func replaceTopController(with viewController: UIViewController) {
        var viewControllers = Array(self.viewControllers.dropLast())
        viewControllers.append(viewController)
        self.viewControllers = viewControllers
    }

    @discardableResult
    func popBackTo<T: UIViewController>(_ viewControllerType: T.Type) -> T? {
        if let targetViewController = self.viewControllers.filter({ type(of: $0) == viewControllerType }).first {
            self.popToViewController(targetViewController, animated: true)
            return targetViewController as? T
        }
        return nil
    }
}
