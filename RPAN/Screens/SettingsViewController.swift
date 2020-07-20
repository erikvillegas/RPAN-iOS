//
//  SettingsViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/10/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import SwiftMessages
import PromiseKit
import FirebaseCrashlytics

class SettingsViewController: UIViewController {
    let tableView = UITableView([ActionButtonCell.self, NotificationSettingCell.self, UserSubscriptionCell.self, DonationButtonCell.self], style: .grouped, {
        $0.rowHeight = UITableView.automaticDimension
        $0.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
    })
    
    var userSubscriptions = [UserSubscription]()
    var datasource = [SettingsDataSource]()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.display(userSubscriptions: SettingsService.shared.savedUserSubscriptions)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        }
        else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
        
        NotificationCenter.default.addObserver(self, selector: #selector(authenticationSuccess(_:)), name: .authenticationSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authenticationFailure(_:)), name: .authenticationFailure, object: nil)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        self.navigationItem.rightBarButtonItem?.tintColor = Colors.primaryOrange
        
        self.display(userSubscriptions: SettingsService.shared.savedUserSubscriptions)
    }
    
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
        
        // hack to get the Home to reload
        if let navigationController = self.presentingViewController as? UINavigationController, let homeViewController = navigationController.topViewController as? HomeViewController {
            homeViewController.displayBroadcasts()
        }
    }
    
    @objc func authenticationSuccess(_ notification:Notification) {
        self.importFollowers()
        AnalyticsService.shared.logEvent("Connect Account Success")
    }
    
    @objc func authenticationFailure(_ notification:Notification) {
        if let error = notification.object as? Error {
            CrashService.shared.logError(error, message: "Connect Account Failure")
        }
        
        self.displayToast(message: "There was a problem connecting your Reddit account, please try again later!", theme: .error)
    }
    
    func importFollowers() {
        guard LoginService.shared.loggedInUser != nil else { return }
        
        self.displayToast(message: "Connecting to Reddit...", theme: .info, duration: .forever)
        
        let connectAccountCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ActionButtonCell
        connectAccountCell?.isUserInteractionEnabled = false
        connectAccountCell?.titleLabel.alpha = 0.5
        
        SettingsService.shared.importUserSubscriptions().then { userSubscriptions -> Promise<[UserSubscription]> in
            return self.downloadMissingProfilePhotos(userSubscriptions: userSubscriptions)
        }.then { userSubscriptions in
            return self.persistProfilePhotos(userSubscriptions: userSubscriptions)
        }.done { userSubscriptions in
            self.display(userSubscriptions: userSubscriptions)
            
            if userSubscriptions.isEmpty {
                self.showSimpleAlert(title: "No Users Found", message: "You don't appear to follow anyone on Reddit.", okTitle: "Yup!", okHandler: nil)
                AnalyticsService.shared.logEvent("Import - No Users Found")
            }
            else {
                AnalyticsService.shared.logEvent("Import - Users Found", metadata: ["count": String(userSubscriptions.count)])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.promptForNotifications()
                }
            }
        }.catch { error in
            CrashService.shared.logError(error, message: "Follower Import Failure")
            self.showSimpleAlert(title: "Import Failed", message: "Unable to import followers, please try again later!")
        }.finally {
            SwiftMessages.sharedInstance.hideAll()
            
            connectAccountCell?.isUserInteractionEnabled = true
            connectAccountCell?.titleLabel.alpha = 1.0
        }
        
        AnalyticsService.shared.logEvent("Import Followers")
    }
    
    @discardableResult
    func promptForNotifications() -> Guarantee<UNAuthorizationStatus> {
        guard !UserDefaultsService.shared.bool(forKey: .promptedForNotifications) else {
            return PushService.getAuthorizationStatus()
        }
        
        AnalyticsService.shared.logEvent("Notification Pre-Prompt (Settings)")
        
        return Guarantee { resolver in
            let message = "Would you like to enable notifications for these users and others you star when they start a broadcast?"
            self.showCustomActionsAlert(title: "Notifications", message: message, actionTitle: "Yes!", cancelTitle: "Maybe Later", actionHandler: { _ in
                UserDefaultsService.shared.set(true, forKey: .promptedForNotifications)
                UserDefaultsService.shared.set(true, forKey: .globalNotificationsOn)
                PushService.registerForRemoteNotifications()
                self.tableView.reloadData()
                
                resolver(.authorized)
            }, cancelHandler: { _ in
                AnalyticsService.shared.logEvent("Notification Pre-Prompt Dismissed (Settings)")
                resolver(.denied)
            })

            UserDefaultsService.shared.set(true, forKey: .seenNotificationPrePrompt)
        }
    }
    
    func downloadMissingProfilePhotos(userSubscriptions: [UserSubscription]) -> Promise<[UserSubscription]> {
        let userSubscriptionsMissingPhotos = userSubscriptions.filter { $0.iconUrl == nil }
        let userSubscriptionsNotMissingPhotos = userSubscriptions.filter { $0.iconUrl != nil }
        
        guard !userSubscriptionsMissingPhotos.isEmpty else {
            return Promise.value(userSubscriptions)
        }
        
        let usernames = userSubscriptionsMissingPhotos.map { $0.username }
        
        return SettingsService.shared.fetchUserProfiles(usernames: usernames).map { profiles in
            let updatedUserSubscriptions = userSubscriptionsMissingPhotos.map { userSubscription -> UserSubscription in
                let correspondingProfile = profiles.first(where: { $0.username == userSubscription.username })
                return userSubscription.withIconUrl(iconUrl: correspondingProfile?.iconUrl)
            }
            
            return updatedUserSubscriptions + userSubscriptionsNotMissingPhotos
        }
    }
    
    func persistProfilePhotos(userSubscriptions: [UserSubscription]) -> Promise<[UserSubscription]> {
        return SettingsService.shared.persistProfileIcons(userSubscriptions: userSubscriptions).map {
            return userSubscriptions
        }.recover { _ -> Guarantee<[UserSubscription]> in
            return Guarantee.value(userSubscriptions)
        }
    }
    
    func display(userSubscriptions: [UserSubscription]) {
        self.userSubscriptions = userSubscriptions.sorted(by: { $0.username.lowercased() < $1.username.lowercased() })
        
        if userSubscriptions.isEmpty {
            self.datasource = [.account]
        }
        else {
            self.datasource = [.account, .notifications]
        }
        
        self.tableView.reloadData()
    }
    
    @objc func notificationSwitchToggled(sender: UISwitch) {
        let notificationsEnabled = sender.isOn
        
        if notificationsEnabled {
            self.promptForNotifications().done { status in
                if status == .authorized {
                    self.updateGlobalNotificationSetting(enabled: notificationsEnabled, switchControl: sender)
                }
                else {
                    sender.isOn = false
                }
            }
        }
        else {
            self.updateGlobalNotificationSetting(enabled: notificationsEnabled, switchControl: sender)
        }
        
        AnalyticsService.shared.logEvent("Global Notification Togged", metadata: ["status": notificationsEnabled ? "on" : "off"])
    }
    
    func updateGlobalNotificationSetting(enabled: Bool, switchControl: UISwitch) {
        SettingsService.shared.updateGlobalNotificationSetting(enabled: enabled).done { _ in
            UserDefaultsService.shared.set(enabled, forKey: .globalNotificationsOn)
            self.tableView.reloadData()
        }.catch { error in
            switchControl.isOn = !switchControl.isOn
            self.displayToast(message: "There was a problem updating this setting, please try again later!", theme: .error)
            CrashService.shared.logError(error, message: "Global Notification Setting Update Failure")
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.datasource[section] {
        case .account:
            return 1
        case .notifications:
            return self.userSubscriptions.count + 1 // one extra for global notifications cell
        case .support:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.datasource[indexPath.section]
        
        switch section {
        case .account:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ActionButtonCell.reuseId, for: indexPath) as? ActionButtonCell else {
                return UITableViewCell()
            }
            
            if let _ = LoginService.shared.loggedInUser?.0.username {
                cell.titleLabel.text = "Disconnect Reddit Account"
            }
            else {
                cell.titleLabel.text = "Connect Reddit Account"
            }
            
            return cell
        case .notifications:
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingCell.reuseId, for: indexPath) as? NotificationSettingCell else {
                    return UITableViewCell()
                }
                
                let globalNotificationsOn = UserDefaultsService.shared.bool(forKey: .globalNotificationsOn)
                cell.configure(title: "Notifications Enabled", enabled: globalNotificationsOn)
                cell.enabledSwitch.addTarget(self, action: #selector(notificationSwitchToggled(sender:)), for: .valueChanged)
                
                return cell
            }
            else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: UserSubscriptionCell.reuseId, for: indexPath) as? UserSubscriptionCell else {
                    return UITableViewCell()
                }
                
                let userSubscription = self.userSubscriptions[indexPath.row - 1]
                cell.configure(userSubscription: userSubscription)
                
                return cell
            }
        case .support:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DonationButtonCell.reuseId, for: indexPath) as? DonationButtonCell else {
                return UITableViewCell()
            }
            
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.datasource.count
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.datasource[section] {
        case .account:
            return "Account"
        case .notifications:
            return "Notifications"
        case .support:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        
        let label = UILabel(labelInit: {
            $0.text = self.tableView(tableView, titleForHeaderInSection: section)
            $0.font = Fonts.bold.size18
            $0.textColor = Colors.dynamicSystemTitle
        })
        
        containerView.addSubview(label)
        label.edgesToSuperview(insets: UIEdgeInsets(top: 18, left: 20, bottom: 4, right: 20))
        
        return containerView
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch self.datasource[section] {
        case .account:
            if let username = LoginService.shared.loggedInUser?.0.username {
                return "Signed in as u/" + username
            }
            else {
                return "This will allow you to import users you follow on Reddit."
            }
        case .notifications:
            return "App designed and developed with ♥️ by u/erikvillegas"
        case .support:
            return "If you're enjoying this app and want to help cover the notification server costs and developer membership fees, consider buying me a coffee! Thanks, you rock! 😎\n\nApp designed and developed with ♥️ by u/erikvillegas"
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionType = self.datasource[section]
        
        let containerView = UIView()
        
        let text = self.tableView(tableView, titleForFooterInSection: section) ?? ""
        let attributedString = NSMutableAttributedString(string: text)
        
        attributedString.addAttributes([
            .font: Fonts.regular.size12,
            .foregroundColor: Colors.darkGray
        ], range: NSMakeRange(0, text.count))
        
        // TODO: change this to .support when adding back donation link
        if sectionType == .notifications {
             attributedString.addAttributes([
                .link: "https://www.reddit.com/user/erikvillegas",
             ], range: (text as NSString).range(of: "u/erikvillegas"))
        }
        
        let textView = UITextView()
        textView.attributedText = attributedString
        textView.delegate = self
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = Colors.clear
        
        containerView.addSubview(textView)
        textView.edgesToSuperview(insets: UIEdgeInsets(top: 4, left: 14, bottom: 0, right: 14))
        
        return containerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let (user, _) = LoginService.shared.loggedInUser {
                self.showCustomActionAlert(title: "Log Out", message: "You sure? Just checkin'", actionTitle: "Yes") { _ in
                    LoginService.shared.logout(user: user)
                    self.tableView.reloadData()
                    AnalyticsService.shared.logEvent("Disconnect Account")
                }
                
                AnalyticsService.shared.logEvent("Disconnect Accoun Button Tapped")
            }
            else {
                let message = "Log in on the following screen and tap \"Allow\" to connect your account.\n\nThis will grant this app read-only access to your Reddit profile. The only data that will be accessed is the list of users you follow."
                self.showCustomActionAlert(title: "Grant Permission", message: message, actionTitle: "OK") { _ in
                    LoginService.shared.authenticateWithReddit()
                    AnalyticsService.shared.logEvent("Connect Account Initiated")
                }
                
                AnalyticsService.shared.logEvent("Connect Button Tapped")
            }
        case 1:
            if indexPath.row != 0 && UserDefaultsService.shared.bool(forKey: .globalNotificationsOn) {
                let userSubscription = self.userSubscriptions[indexPath.row - 1]
                let notificationsVC = NotificationsViewController(userSubscription: userSubscription)
                notificationsVC.delegate = self
                self.navigationController?.pushViewController(notificationsVC, animated: true)
                AnalyticsService.shared.logScreenView(NotificationsViewController.self)
                AnalyticsService.shared.logEvent("Open Notification Settings", metadata: ["userSubscription" : userSubscription.username])
            }
        case 2:
            UIApplication.shared.open(URL(string: "https://ko-fi.com/erikv")!)
            AnalyticsService.shared.logEvent("Donate Link Tapped")
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsViewController: NotificationsViewControllerDelegate {
    func unsubscribeAction(userSubscription: UserSubscription) {
        SettingsService.shared.removeFavorite(broadcaster: userSubscription.username).done { _ in
            let newUserSubscriptions = self.userSubscriptions.filter { $0 != userSubscription }
            self.display(userSubscriptions: newUserSubscriptions)
        }.catch { error in
            self.displayToast(message: "Unable to unfavorite this user, please try again later!", theme: .error)
            CrashService.shared.logError(error, message: "Unable To Unfavorite (Settings)")
            
        }
    }
    
    func updatedUserSubscription(userSubscription: UserSubscription) {
        if let index = self.userSubscriptions.firstIndex(of: userSubscription) {
            self.userSubscriptions[Int(index)] = userSubscription
            self.display(userSubscriptions: self.userSubscriptions)
            
            SettingsService.shared.savedUserSubscriptions = self.userSubscriptions
        }
    }
}

extension SettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        AnalyticsService.shared.logEvent("My Profile Button Tapped")
        return false
    }
}
