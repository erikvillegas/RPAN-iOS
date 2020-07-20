//
//  SubredditBlacklistViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/13/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftMessages

class SubredditCell: UITableViewCell {
    let iconImageView = UIImageView(imageViewInit: {
        $0.width(26)
        $0.height(26)
        $0.layer.cornerRadius = 13
        $0.layer.masksToBounds = true
    })
    
    let titleLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
    })
    
    let enabledSwitch = UISwitch(switchInit: {
        $0.onTintColor = Colors.primaryOrange
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.iconImageView)
        self.iconImageView.centerYToSuperview()
        self.iconImageView.leftToSuperview(offset: 20)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.centerYToSuperview()
        self.titleLabel.leftToRight(of: self.iconImageView, offset: 12)
        
        self.contentView.addSubview(self.enabledSwitch)
        self.enabledSwitch.centerY(to: self.titleLabel)
        self.enabledSwitch.rightToSuperview(offset: -20)
        
        self.selectionStyle = .none
    }
    
    func configure(title: String, enabled: Bool) {
        self.titleLabel.text = title
        self.enabledSwitch.isOn = enabled
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

protocol SubredditBlacklistViewControllerDelegate: class {
    func updatedUserSubscriptionWithBlacklistSetting(userSubscription: UserSubscription)
}

class SubredditBlacklistViewController: UIViewController {
    let tableView = UITableView([SubredditCell.self], style: .grouped, {
        $0.rowHeight = UITableView.automaticDimension
    })
    
    var userSubscription: UserSubscription
    var delegate: SubredditBlacklistViewControllerDelegate?
    
    var subreddits = [RpanSubreddit]()
    
    init(userSubscription: UserSubscription) {
        self.userSubscription = userSubscription
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Subreddits"
        
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
        
        let headerLabel = UILabel()
        headerLabel.font = Fonts.regular.size12
        headerLabel.textColor = Colors.darkGray
        headerLabel.numberOfLines = 0
        headerLabel.text = "If you would like to NOT receive notifications when u/\(self.userSubscription.username) broadcasts from specific subreddits, disable the subreddit below. Any new subreddits added to RPAN in the future will be enabled by default."
        
        let headerView = UIView()
        headerView.addSubview(headerLabel)
        headerLabel.edgesToSuperview(insets: UIEdgeInsets(top: 8, left: 20, bottom: 0, right: 20))
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 94)
        
        self.tableView.tableHeaderView = headerView
        
        self.fetchSubreddits()
    }
    
    func fetchSubreddits() {
        self.displayToast(message: "Connecting to Reddit...", theme: .info, duration: .indefinite(delay: 1.0, minimum: 2.0))
        
        SettingsService.shared.fetchSubreddits().done { subreddits in
            self.subreddits = subreddits
            self.tableView.reloadData()
        }.catch { error in
            self.showSimpleAlert(title: "Oops", message: "Unable to fetch list of subreddits, please try again later!")
            CrashService.shared.logError(error, message: "Unable To Fetch Subreddits")
        }.finally {
            SwiftMessages.sharedInstance.hideAll()
        }
    }
    
    @objc func subredditSwitchToggled(sender: UISwitch) {
        let subreddit = self.subreddits[sender.tag]
        
        var updatedBlacklist = self.userSubscription.subredditBlacklist
        
        if sender.isOn {
            updatedBlacklist.removeAll { $0 == subreddit.name }
        }
        else {
            updatedBlacklist += subreddit.name
        }
        
        SettingsService.shared.updateSubredditBlacklistSetting(userSubscription: self.userSubscription, subreddits: updatedBlacklist).done { _ in
            let updatedUserSubscription = self.userSubscription.withSubredditBlacklist(subreddits: updatedBlacklist)
            self.userSubscription = updatedUserSubscription
            self.delegate?.updatedUserSubscriptionWithBlacklistSetting(userSubscription: updatedUserSubscription)
        }.catch { error in
            self.displayToast(message: "An expected error occurred, please try again later!", theme: .error)
            CrashService.shared.logError(error, message: "Unable To Toggle Subreddit Blacklist")
            sender.isOn = !sender.isOn
        }
        
        AnalyticsService.shared.logEvent("Subreddit Blacklist Switch Toggled", metadata: [
            "subreddit": subreddit.name,
            "broadcaster": self.userSubscription.username,
            "status": sender.isOn ? "on" : "off"])
    }
}

extension SubredditBlacklistViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.subreddits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subreddit = self.subreddits[indexPath.row]
        
        let cell = SubredditCell(style: .default, reuseIdentifier: nil)
        cell.titleLabel.text = "r/" + subreddit.name
        cell.iconImageView.kf.setImage(with: subreddit.iconUrl)
        
        cell.enabledSwitch.tag = indexPath.row
        cell.enabledSwitch.isOn = !self.userSubscription.subredditBlacklist.contains(subreddit.name)
        cell.enabledSwitch.addTarget(self, action: #selector(subredditSwitchToggled(sender:)), for: .valueChanged)
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension SubredditBlacklistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Enabled Subreddits"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 { // unfavorite user
            let message = "You will no longer receive notifications for this user and their streams won't appear at the top of your feed"
            self.showCustomActionAlert(title: "Are you sure?", message: message, actionTitle: "Yes") { _ in
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
