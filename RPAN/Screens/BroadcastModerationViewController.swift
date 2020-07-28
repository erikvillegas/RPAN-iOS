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

class CommentCell: UITableViewCell {
    struct Constants {}
    
    let avatarMaskView = UIView(viewInit: {
        $0.width(24.0)
        $0.height(24.0)
        $0.layer.cornerRadius = 3.0
        $0.layer.borderColor = Colors.dynamicThumbnailHighlight.cgColor
        $0.layer.borderWidth = 1
    })
    
    let avatarImageView = UIImageView(imageViewInit: {
        $0.layer.cornerRadius = 3.0
        $0.layer.masksToBounds = true
        $0.contentMode = .scaleAspectFill
    })
    
    let usernameLabel = UILabel(labelInit: {
        $0.font = Fonts.bold.size14
        $0.textColor = Colors.dynamicSystemTitle
//        $0.setCompressionResistance(.init(rawValue: 999), for: .vertical)
    })
    
    let bodyLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size14
        $0.textColor =  Colors.dynamicSystemTitle
        $0.numberOfLines = 0
    })
    
    let timestampLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size10
        $0.textColor =  Colors.darkGray
        $0.numberOfLines = 1
    })
    
    let reportIconImageView = UIImageView(imageViewInit: {
        $0.image = #imageLiteral(resourceName: "report-icon")
        $0.size(CGSize(width: 12, height: 16.3))
    })
    
    let removedIconImageView = UIImageView(imageViewInit: {
        $0.image = #imageLiteral(resourceName: "removed-icon")
        $0.size(CGSize(width: 12, height: 14))
    })
    
    let automodIconImageView = UIImageView(imageViewInit: {
        $0.image = #imageLiteral(resourceName: "shield-icon")
        $0.size(CGSize(width: 12, height: 13.4))
    })
    
    lazy var thumbnailStackView = UIStackView([self.avatarMaskView, SpacerView.vertical]) {
        $0.axis = .vertical
    }
    
    lazy var topLabelStackView = UIStackView([self.usernameLabel, self.timestampLabel, SpacerView.horizontal, self.removedIconImageView, self.reportIconImageView, self.automodIconImageView]) {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 8.0
        $0.setCustomSpacing(11, after: self.removedIconImageView)
        $0.setCustomSpacing(11, after: self.reportIconImageView)
    }

    lazy var mainLabelStackView = UIStackView([self.topLabelStackView, self.bodyLabel]) {
        $0.axis = .vertical
        $0.spacing = 5.0
    }
    
    lazy var mainStackView = UIStackView([self.thumbnailStackView, self.mainLabelStackView]) {
        $0.axis = .horizontal
        $0.spacing = 12
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.avatarMaskView.addSubview(self.avatarImageView)
        self.avatarImageView.edgesToSuperview()
        
        self.contentView.addSubview(self.mainStackView)
        self.mainStackView.edgesToSuperview(insets: UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 16))
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(comment: Comment) {
        self.usernameLabel.text = comment.author
        self.bodyLabel.text = comment.body
        
        let colors = ["FF4500", "0DD3BB", "24A0ED", "FFB000", "FF8717", "46D160", "25B79F", "0079D3", "4856A3", "C18D42", "A06A42", "46A508", "008985", "7193FF", "7E53C1", "FFD635", "DDBD37", "D4E815", "94E044", "FF66AC", "DB0064", "FF585B", "EA0027", "A5A4A4", "545452"]
        
        let encodedBase36 = comment.authorFullname.dropFirst(3) // `authorFullname` is user ID, such as "t2_12pzg5". We have to remove "t2_" before we can use it
        let decodedBase36 = Int(encodedBase36, radix: 36)! // convert the base36 string to an integer
        let avatarIndex = decodedBase36 % 20 + 1 // 20 avatar variations max
        let colorIndex = Int(floor(Double(decodedBase36)/20.0)) % colors.count
        
        let avatar = ("0" + String(avatarIndex)).suffix(2) // use only last two digits (aka chop the zero off)
        let color = colors[colorIndex]
        
        let url = URL(string: "https://www.redditstatic.com/avatars/avatar_default_\(avatar)_\(color).png")!
        
        self.avatarImageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "default-avatar"))
        
        let createdDate = Date(timeIntervalSince1970: TimeInterval(comment.createdUtc))
        self.timestampLabel.text = createdDate.toRelative(since: Date().inDefaultRegion(), style: .some(.init(flavours: [.shortConvenient], gradation: .twitter())), locale: nil)
        
        self.reportIconImageView.isHidden = comment.numReports == 0
        
        if comment.bannedBy == "AutoModerator" {
            self.automodIconImageView.isHidden = false
            self.removedIconImageView.isHidden = true
        }
        else if comment.removed {
            self.automodIconImageView.isHidden = true
            self.removedIconImageView.isHidden = false
        }
        else {
            self.automodIconImageView.isHidden = true
            self.removedIconImageView.isHidden = true
        }
    }
}

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
            print(comments.count)
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
            
            cell.configure(broadcast: self.broadcast)
            cell.subscribeButton.tag = indexPath.row
            cell.subscribeButton.isHidden = true
            
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
