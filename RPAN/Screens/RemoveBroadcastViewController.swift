//
//  RemoveBroadcastViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/31/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import reddift

class RemoveBroadcastViewController: UIViewController {
    let broadcast: Broadcast
    var reasons = [RemovalReason]()
    var selectedReasonIndex = 0
    
    let tableView = UITableView([SubredditRuleCell.self], style: .grouped, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
        $0.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
    })
    
    init(broadcast: Broadcast) {
        self.broadcast = broadcast
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Remove Broadcast"
        
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "REMOVE", style: .done, target: self, action: #selector(removeBroadcastTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        ModerationService.shared.subredditRemovalReasons(subreddit: self.broadcast.post.subreddit.name).done { reasons in
            self.reasons = reasons
            self.tableView.reloadData()
        }.catch { error in
            self.showSimpleAlert(title: "Oops", message: "Unable to load subreddit removal reasons")
        }
    }
    
    @objc func removeBroadcastTapped(sender: UIButton) {
        let subreddit = self.broadcast.post.subreddit.name
        let reason = self.reasons[self.selectedReasonIndex]
        let reasonString = reason.title.hasSuffix(".") ? String(reason.title.dropLast()) : reason.title
        let message = "Remove broadcast \"\(self.broadcast.post.title)\" from\nr/\(subreddit) for reason:\n\"\(reasonString)\"?"
        
        self.showCustomActionAlert(title: "Removal Confirmation", message: message, actionTitle: "Removal") { _ in
            ModerationService.shared.remove(self.broadcast).then { _ in
                return ModerationService.shared.addRemoveReason(broadcast: self.broadcast, reason: reason)
            }.done { _ in
                let message = "Successfully removed post"
                self.displayToast(message: message, theme: .success, duration: .seconds(seconds: 1))

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let homeVC = (self.presentingViewController?.presentingViewController as? UINavigationController)?.topViewController as? HomeViewController {
                        homeVC.dismiss(animated: true, completion: nil)
                    }
                }
            }.catch { error in
                self.showSimpleAlert(title: "Oops", message: "Something went wrong, please try again later!")
            }
        }
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension RemoveBroadcastViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reasons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubredditRuleCell.reuseId, for: indexPath) as? SubredditRuleCell else {
            return UITableViewCell()
        }
        
        cell.nameLabel.text = self.reasons[indexPath.row].title
        cell.accessoryType = (indexPath.row == self.selectedReasonIndex) ? .checkmark : .none
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension RemoveBroadcastViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedReasonIndex = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Reason"
    }
}

