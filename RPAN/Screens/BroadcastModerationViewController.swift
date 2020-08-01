//
//  BroadcastModerationViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/24/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import reddift
import PromiseKit
import SwiftDate
import SwiftMessages

enum BroadcastModerationDatasource {
    case broadcast
    case reportedComments
    case flaggedComments
    case removedComments
    case latestComments
}

class BroadcastModerationViewController: UIViewController {
    let broadcast: Broadcast
    var comments = [Comment]()
    var reportedComments = [Comment]()
    var flaggedByAutoModComments = [Comment]()
    var removedComments = [Comment]()
    
    var datasource = [BroadcastModerationDatasource]()
    
    let tableView = UITableView([BroadcastCell.self, CommentCell.self], style: .plain, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
    })
    
    let refreshControl = UIRefreshControl()
    
    init(broadcast: Broadcast) {
        self.broadcast = broadcast
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        }
        else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.title = "Broadcast Moderation"
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        self.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.refreshData()
        
        AnalyticsService.shared.logScreenView(BroadcastModerationViewController.self)
    }
    
    @objc func refreshData() {
        self.displayToast(message: "Loading all comments...", theme: .info)
        
        RedditAPI.shared.getComments(broadcast: self.broadcast).done { comments in
            self.comments = comments.filter { $0.author != "AutoModerator" }
            self.reportedComments = self.comments.filter { $0.numReports > 0 }
            self.flaggedByAutoModComments = self.comments.filter { $0.bannedBy == "AutoModerator" }
            self.removedComments = self.comments.filter { $0.removed }
            
            self.datasource = [.broadcast]
            
            if !self.reportedComments.isEmpty {
                self.datasource += .reportedComments
            }
            
            if !self.flaggedByAutoModComments.isEmpty {
                self.datasource += .flaggedComments
            }
            
            if !self.removedComments.isEmpty {
                self.datasource += .removedComments
            }
            
            self.datasource += .latestComments
            
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }.catch { error in
            print(error)
            self.refreshControl.endRefreshing()
        }.finally {
            SwiftMessages.sharedInstance.hideAll()
        }
    }
    
    func removeComment(_ comment: Comment) {
        ModerationService.shared.remove(comment).done { _ in
            self.displayToast(message: "Successfully removed comment", theme: .success)
        }.catch { _ in
            self.displayToast(message: "Unable to remove comment", theme: .error)
        }
    }
    
    func approveComment(_ comment: Comment) {
        ModerationService.shared.approve(comment).done { _ in
            self.displayToast(message: "Successfully approved comment", theme: .success)
        }.catch { _ in
            self.displayToast(message: "Unable to remove comment", theme: .error)
        }
    }
    
    func banUser(comment: Comment) {
        let banUserVC = BanUserViewController(broadcast: self.broadcast, comment: comment)
        let navigationController = UINavigationController(rootViewController: banUserVC)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func removeButtonTapped() {
        let removeVC = RemoveBroadcastViewController(broadcast: self.broadcast)
        let navigationController = UINavigationController(rootViewController: removeVC)
        self.present(navigationController, animated: true, completion: nil)
    }
}

extension BroadcastModerationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.datasource[section] {
        case .broadcast:
            return 1
        case .reportedComments:
            return self.reportedComments.count
        case .flaggedComments:
            return self.flaggedByAutoModComments.count
        case .removedComments:
            return self.removedComments.count
        case .latestComments:
            return self.comments.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.datasource[indexPath.section] {
        case .broadcast:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BroadcastCell.reuseId, for: indexPath) as? BroadcastCell else {
                return UITableViewCell()
            }
            
            cell.configure(broadcast: self.broadcast, moderatorView: true)
            cell.removalButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
            
            return cell
        case .reportedComments:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as? CommentCell else {
                return UITableViewCell()
            }
            
            cell.configure(comment: self.reportedComments[indexPath.row])
            
            return cell
        case .flaggedComments:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as? CommentCell else {
                return UITableViewCell()
            }
            
            cell.configure(comment: self.flaggedByAutoModComments[indexPath.row])
            
            return cell
        case .removedComments:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as? CommentCell else {
                return UITableViewCell()
            }
            
            cell.configure(comment: self.removedComments[indexPath.row])
            
            return cell
        case .latestComments:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseId, for: indexPath) as? CommentCell else {
                return UITableViewCell()
            }
            
            cell.configure(comment: self.comments[indexPath.row])
            
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.datasource.count
    }
}

extension BroadcastModerationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.datasource[indexPath.section]
        let comment: Comment
        
        switch item {
        case .broadcast:
            return
        case .reportedComments:
            comment = self.reportedComments[indexPath.row]
        case .flaggedComments:
            comment = self.flaggedByAutoModComments[indexPath.row]
        case .removedComments:
            comment = self.removedComments[indexPath.row]
        case .latestComments:
            comment = self.comments[indexPath.row]
        }
        
        let truncatedComment = comment.body.prefix(50)
        var commentBody = "\"" + (comment.body.count > 50 ? truncatedComment + "..." : truncatedComment) + "\""
        
        if !comment.bannedBy.isEmpty && comment.bannedBy != "AutoModerator" {
            commentBody += "\nRemoved by u/\(comment.bannedBy)"
        }
        
        let actionSheet = UIAlertController(title: nil, message: String(commentBody), preferredStyle: .actionSheet)
        
        if comment.bannedBy.isEmpty || comment.bannedBy == "AutoModerator" {
            actionSheet.addAction(UIAlertAction(title: "Remove Comment", style: .default, handler: { [weak self] _ in
                self?.removeComment(comment)
            }))
        }
        
        if !comment.bannedBy.isEmpty {
            actionSheet.addAction(UIAlertAction(title: "Approve Comment", style: .default, handler: { [weak self] _ in
                self?.approveComment(comment)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Ban User...", style: .default, handler: { [weak self] _ in
            self?.banUser(comment: comment)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.view.tintColor = Colors.primaryOrange
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.datasource[section] {
        case .broadcast:
            return nil
        case .reportedComments:
            return "Reported Comments"
        case .flaggedComments:
            return "Flagged By AutoModerator"
        case .removedComments:
            return "Removed Comments"
        case .latestComments:
            return "Latest Comments"
        }
    }
}
