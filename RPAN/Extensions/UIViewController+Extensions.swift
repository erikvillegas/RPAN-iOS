//
//  UIViewController+Extensions.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import SwiftMessages

extension UIViewController {
    func displayToast(message: String, theme: Theme, duration: SwiftMessages.Duration = .automatic) {
        let view = MessageView.viewFromNib(layout: .statusLine)

        view.configureContent(body: message)
        
        if theme == .info {
            view.configureTheme(backgroundColor: Colors.primaryOrange, foregroundColor: Colors.white)
        }
        else {
            view.configureTheme(theme)
        }
        
        view.layoutMarginAdditions = .uniform(16)
        
        var config = SwiftMessages.Config()
        config.presentationContext = .viewController(self)
        config.duration = duration

        SwiftMessages.show(config: config, view: view)
    }
}

