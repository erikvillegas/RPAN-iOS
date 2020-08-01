//
//  NotificationsViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/11/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import FirebaseCrashlytics

protocol NotificationsViewControllerDelegate: class {
    func updatedUserSubscription(userSubscription: UserSubscription)
    func unsubscribeAction(userSubscription: UserSubscription)
}

class NotificationsViewController: UIViewController {
    let tableView = UITableView([], style: .grouped, {
        $0.rowHeight = UITableView.automaticDimension
    })
    
    var userSubscription: UserSubscription
    var delegate: NotificationsViewControllerDelegate?
    
    init(userSubscription: UserSubscription) {
        self.userSubscription = userSubscription
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "u/" + self.userSubscription.username
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        }
        else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            if let settingsViewController = self.navigationController?.viewControllers.first as? SettingsViewController {
                settingsViewController.display(userSubscriptions: SettingsService.shared.savedUserSubscriptions)
            }
        }
    }
    
    @objc func notificationSwitchToggled(sender: UISwitch) {
        let notificationsEnabled = sender.isOn
        var allUserSubscriptions = SettingsService.shared.savedUserSubscriptions
        
        if let index = allUserSubscriptions.firstIndex(of: self.userSubscription) {
            let updatedUserSubscription = self.userSubscription.withNotifications(enabled: notificationsEnabled)
            allUserSubscriptions[Int(index)] = updatedUserSubscription
            SettingsService.shared.savedUserSubscriptions = allUserSubscriptions
            self.userSubscription = updatedUserSubscription
        }
        
        SettingsService.shared.updateNotificationSetting(userSubscription: self.userSubscription, enabled: notificationsEnabled).catch { error in
            sender.isOn = !sender.isOn
            self.displayToast(message: "There was a problem updating this setting, please try again later!", theme: .error)
            CrashService.shared.logError(error, message: "Unable To Toggle Subscriber Notification")
        }
        
        self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0), IndexPath(row: 3, section: 0)], with: .automatic)
        
        AnalyticsService.shared.logEvent("Broadcaster Notification Switch Toggled", metadata: ["status": notificationsEnabled ? "on" : "off"])
    }
    
    @objc func cooldownSwitchToggled(sender: UISwitch) {
        let cooldownEnabled = sender.isOn
        var allUserSubscriptions = SettingsService.shared.savedUserSubscriptions
        
        if let index = allUserSubscriptions.firstIndex(of: self.userSubscription) {
            let updatedUserSubscription = self.userSubscription.withCooldown(enabled: cooldownEnabled)
            allUserSubscriptions[Int(index)] = updatedUserSubscription
            SettingsService.shared.savedUserSubscriptions = allUserSubscriptions
        }
        
        SettingsService.shared.updateCooldownSetting(userSubscription: self.userSubscription, enabled: cooldownEnabled).catch { error in
            sender.isOn = !sender.isOn
            self.displayToast(message: "There was a problem updating this setting, please try again later!", theme: .error)
            CrashService.shared.logError(error, message: "Unable To Toggle Cooldown")
        }
        
        AnalyticsService.shared.logEvent("Broadcaster Cooldown Switch Toggled", metadata: ["status": cooldownEnabled ? "on" : "off"])
    }
}

extension NotificationsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let cell = TitleAndSwitchCell(style: .default, reuseIdentifier: nil)
                cell.configure(title: "Notify when going live", enabled: self.userSubscription.notify)
                cell.enabledSwitch.addTarget(self, action: #selector(notificationSwitchToggled(sender:)), for: .valueChanged)
                
                return cell
            case 1:
                let cell = TitleDetailCell(style: .default, reuseIdentifier: nil)
                
                cell.titleLabel.text = "Notification Sound"
                cell.detailLabel.text = self.userSubscription.soundDisplayName
                
                cell.selectionStyle = self.userSubscription.notify ? .default : .none
                cell.titleLabel.alpha = self.userSubscription.notify ? 1.0 : 0.5
                cell.detailLabel.alpha = self.userSubscription.notify ? 1.0 : 0.5
                
                return cell
            case 2:
                let cell = TitleDetailCell(style: .default, reuseIdentifier: nil)
                let subredditCount = self.userSubscription.subredditBlacklist.count
                
                cell.titleLabel.text = "Ignore broadcasts from subreddits"
                cell.detailLabel.text = subredditCount > 0 ? String(self.userSubscription.subredditBlacklist.count) : nil
                
                cell.selectionStyle = self.userSubscription.notify ? .default : .none
                cell.titleLabel.alpha = self.userSubscription.notify ? 1.0 : 0.5
                cell.detailLabel.alpha = self.userSubscription.notify ? 1.0 : 0.5
                
                return cell
            case 3:
                let cell = TitleAndSwitchCell(style: .default, reuseIdentifier: nil)
                cell.configure(title: "Cooldown Enabled", enabled: self.userSubscription.cooldown)
                cell.enabledSwitch.addTarget(self, action: #selector(cooldownSwitchToggled(sender:)), for: .valueChanged)
                
                cell.titleLabel.alpha = self.userSubscription.notify ? 1.0 : 0.35
                cell.enabledSwitch.alpha = self.userSubscription.notify ? 1.0 : 0.35
                cell.enabledSwitch.isEnabled = self.userSubscription.notify
                
                return cell
            default: break
            }
        }
        else {
            let cell = ActionButtonCell(style: .default, reuseIdentifier: nil)
            cell.titleLabel.text = "Unfavorite User"
            cell.titleLabel.textColor = UIColor.red
            
            return cell
        }

        return UITableViewCell()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}

extension NotificationsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Notifications"
        default: return nil
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                guard self.userSubscription.notify else { return }
                let vc = SoundsViewController(userSubscription: self.userSubscription)
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
            }
            else if indexPath.row == 2 {
                guard self.userSubscription.notify else { return }
                let vc = SubredditBlacklistViewController(userSubscription: self.userSubscription)
                vc.delegate = self
                self.navigationController?.pushViewController(vc, animated: true)
                AnalyticsService.shared.logScreenView(SubredditBlacklistViewController.self)
            }
        }
        else if indexPath.section == 1 { // unfavorite user
            let message = "You will no longer receive notifications for this user and their streams won't appear at the top of your feed"
            self.showCustomActionAlert(title: "Are you sure?", message: message, actionTitle: "Yes") { _ in
                self.delegate?.unsubscribeAction(userSubscription: self.userSubscription)
                self.navigationController?.popViewController(animated: true)
                AnalyticsService.shared.logEvent("Unfavorited User (Settings)", metadata: ["broadcaster": self.userSubscription.username])
            }
            
            AnalyticsService.shared.logEvent("Unfavorite User (Settings)", metadata: ["broadcaster": self.userSubscription.username])
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Enabling cooldown will ensure you do not get more than one notification from this broadcaster in a 4 hour period. This may be useful for broadcasters that frequently do back-to-back broadcasts over several hours."
        default: return nil
        }
    }
}

extension NotificationsViewController: SubredditBlacklistViewControllerDelegate {
    func updatedUserSubscriptionWithBlacklistSetting(userSubscription: UserSubscription) {
        self.userSubscription = userSubscription
        self.tableView.reloadData()
        
        self.delegate?.updatedUserSubscription(userSubscription: userSubscription)
    }
}

extension NotificationsViewController: SoundsViewControllerDelegate {
    func updatedUserSubscriptionWithSoundSetting(userSubscription: UserSubscription) {
        self.userSubscription = userSubscription
        self.tableView.reloadData()
        
        self.delegate?.updatedUserSubscription(userSubscription: userSubscription)
    }
}
