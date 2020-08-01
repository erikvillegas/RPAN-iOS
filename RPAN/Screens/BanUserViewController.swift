//
//  BanUserViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/25/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import PromiseKit
import reddift

class SubredditRuleCell: UITableViewCell {
    let nameLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size18
        $0.textColor =  Colors.dynamicSystemTitle
        $0.numberOfLines = 0
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.nameLabel)
        self.nameLabel.edgesToSuperview(insets: UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 28))
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

class BanDurationCell: UITableViewCell {
    let durationLabel = UILabel(labelInit: {
        $0.text = "Permanent"
        $0.font = Fonts.regular.size18
        $0.textColor =  Colors.dynamicSystemTitle
        $0.width(120)
    })
    
    let slider = UISlider()
    
    lazy var mainStackView = UIStackView([self.durationLabel, self.slider]) {
        $0.axis = .horizontal
        $0.spacing = 16
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.slider.value = 1
        
        self.contentView.addSubview(self.mainStackView)
        self.mainStackView.edgesToSuperview(insets: UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
        
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

class BanUserViewController: UIViewController {
    let broadcast: Broadcast
    let comment: Comment
    var rules = [SubredditRules.Rule]()
    var selectedRuleIndex = 0
    var currentBanDuration = -1
    var alsoRemoveComment = true
    
    let tableView = UITableView([CommentCell.self, TitleAndSwitchCell.self, BanDurationCell.self, SubredditRuleCell.self], style: .grouped, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
        $0.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
    })
    
    init(broadcast: Broadcast, comment: Comment) {
        self.broadcast = broadcast
        self.comment = comment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Ban u/\(self.comment.author)"
        
        if #available(iOS 13.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                self.view.backgroundColor = UIColor.systemBackground
            }
            else {
                self.view.backgroundColor = Colors.lightGray
            }
        }
        else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "BAN", style: .done, target: self, action: #selector(banButtonTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        ModerationService.shared.subredditRules(subredditName: self.broadcast.post.subreddit.name).done { rules in
            let sorted = rules.sorted(by: { r1, r2 in r1.shortName.contains("respect") })
            self.rules = sorted
            self.tableView.reloadData()
        }.catch { error in
            self.showSimpleAlert(title: "Oops", message: "Unable to load subreddit rules")
        }
    }
    
    @objc func durationSliderUpdated(slider: UISlider) {
        let options = [1, 2, 3, 5, 7, 14, -1] // -1 means permanent
        
        let optionIndex = Int(roundf(slider.value * Float(options.count - 1)))
        let currentOption = options[optionIndex]
        
        if let cell = self.tableView.visibleCells.first(where: { $0 is BanDurationCell }) as? BanDurationCell {
            if currentOption == options.last! {
                cell.durationLabel.text = "Permanent"
            }
            else {
                let plurality = currentOption == 1 ? "Day" : "Days"
                cell.durationLabel.text = "\(currentOption) \(plurality)"
            }
        }
        
        self.currentBanDuration = currentOption
    }
    
    @objc func banButtonTapped(sender: UIButton) {
        let durationString: String
        if self.currentBanDuration == -1 {
            durationString = "permanently"
        }
        else if self.currentBanDuration == 1 {
            durationString = "for one day"
        }
        else {
            durationString = "for \(self.currentBanDuration) days"
        }
        
        let subreddit = self.broadcast.post.subreddit.name
        
        let rule = self.rules[self.selectedRuleIndex]
        let ruleString = rule.shortName.hasSuffix(".") ? String(rule.shortName.dropLast()) : rule.shortName
        let message = "Ban u/\(self.comment.author) \(durationString) from\nr/\(subreddit) for reason:\n\"\(ruleString)\"?"
        self.showCustomActionAlert(title: "Ban Confirmation", message: message, actionTitle: "Ban") { _ in
            let duration = self.currentBanDuration == -1 ? nil : self.currentBanDuration
            
            let banMessage = """
               **This comment may have fully or partially contributed to your ban**:
                \n---
                \n\"\(self.comment.body)\"
                \n---
                \n**\(rule.shortName)**
                \n\(rule.description ?? "")
                \n---
                \n[^(context)](\(self.broadcast.post.url.absoluteString)?context=9) ^| [^(sub rules)](http://www.reddit.com/r/\(subreddit)/about/rules) ^| [^(wiki)](https://www.reddit.com/r/\(subreddit)/wiki/index) ^|  [^(RPAN rules)](https://www.redditinc.com/policies/broadcasting-content-policy) ^| [^(site rules)](http://www.reddit.com/rules) ^| [^cat](http://i.imgur.com/Gbx2Vts.gifv)
            """
            
            ModerationService.shared.ban(self.comment.author, from: subreddit, banMessage: banMessage, modNote: nil, reason: rule.shortName, duration: duration, comment: self.comment).then { _ -> Promise<Void> in
                if self.alsoRemoveComment {
                    return ModerationService.shared.remove(self.comment)
                }
                else {
                    return Promise.value(())
                }
            }.done { _ in
                let message = "Successfully banned user\(self.alsoRemoveComment ? " and removed comment" : "")"
                self.displayToast(message: message, theme: .success, duration: .seconds(seconds: 1))
                
                if let broadcastModerationVC = (self.presentingViewController! as? UINavigationController)?.topViewController as? BroadcastModerationViewController {
                    broadcastModerationVC.refreshData()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.dismiss(animated: true, completion: nil)
                }
            }.catch { error in
                print(error)
                if let serviceError = error as? ModerationServiceError, serviceError == .userIsAlreadyBanned {
                    self.showSimpleAlert(title: "Oops", message: "Looks like someone already banned this user.")
                }
                else {
                    self.showSimpleAlert(title: "Oops", message: "Something went wrong, please try again later! Double check you are able to moderate this subreddit.")
                }
            }
        }
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func alsoRemoveCommentSwitchValueChanged(sender: UISwitch) {
        self.alsoRemoveComment = sender.isOn
    }
}

extension BanUserViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return self.rules.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as? CommentCell else {
                    return UITableViewCell()
                }
                
                cell.configure(comment: self.comment)
                
                return cell
            }
            else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TitleAndSwitchCell.reuseId, for: indexPath) as? TitleAndSwitchCell else {
                    return UITableViewCell()
                }
                
                cell.titleLabel.text = "Also Remove Comment"
                cell.titleLabel.textColor = Colors.dynamicSystemTitle
                cell.enabledSwitch.isOn = self.alsoRemoveComment
                cell.enabledSwitch.addTarget(self, action: #selector(alsoRemoveCommentSwitchValueChanged(sender:)), for: .valueChanged)
                
                return cell
            }
        }
        else if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BanDurationCell.reuseId, for: indexPath) as? BanDurationCell else {
                return UITableViewCell()
            }
            
            cell.slider.addTarget(self, action: #selector(self.durationSliderUpdated(slider:)), for: .valueChanged)
            
            return cell
        }
        else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SubredditRuleCell.reuseId, for: indexPath) as? SubredditRuleCell else {
                return UITableViewCell()
            }
            
            cell.nameLabel.text = self.rules[indexPath.row].shortName
            cell.accessoryType = (indexPath.row == self.selectedRuleIndex) ? .checkmark : .none
            
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
}

extension BanUserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            self.selectedRuleIndex = indexPath.row
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Comment"
        case 1:
            return "Duration"
        case 2:
            return "Reason"
        default:
            return nil
        }
    }
}
