//
//  CommentCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/31/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import reddift

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
    
    lazy var topLabelStackView = UIStackView([self.usernameLabel, self.timestampLabel, SpacerView.horizontal, self.reportIconImageView, self.removedIconImageView, self.automodIconImageView]) {
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
