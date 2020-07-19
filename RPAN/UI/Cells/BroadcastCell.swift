//
//  BroadcastCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class BroadcastCell: UITableViewCell {
    struct Constants {
        static let thumbnailWidth: CGFloat = 60
        static let thumbnailHeight: CGFloat = 106
    }
    
    let thumbnailMaskView = UIView(viewInit: {
        $0.layer.cornerRadius = 4.0
        $0.layer.borderColor = Colors.dynamicThumbnailHighlight.cgColor
        $0.layer.borderWidth = 1
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        $0.layer.shadowOpacity = 0.3
        $0.layer.shadowRadius = 3.0
    })
    
    let thumbnailImageView = UIImageView(imageViewInit: {
        $0.width(Constants.thumbnailWidth)
        $0.height(Constants.thumbnailHeight)
        $0.layer.cornerRadius = 4.0
        $0.layer.masksToBounds = true
        $0.contentMode = .scaleAspectFill
    })
    
    let thumbnailAwardImageView = UIImageView(imageViewInit: {
        $0.width(26.0)
        $0.height(26.0)
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 2, height: 2)
        $0.layer.shadowOpacity = 0.8
        $0.layer.shadowRadius = 5.0
    })
    
    let timeIndicatorView = UIView(viewInit: {
        $0.backgroundColor = Colors.primaryOrange
        $0.layer.cornerRadius = 1
        $0.layer.masksToBounds = true
    })
    
    lazy var timeIndicatorStackView = UIStackView([self.timeIndicatorView, SpacerView.horizontal]) {
        $0.axis = .horizontal
        $0.addBackground(color: Colors.regularGray, cornerRadius: 1)
    }
    
    lazy var thumbnailStackView = UIStackView([self.thumbnailMaskView, self.timeIndicatorStackView, SpacerView.vertical]) {
        $0.axis = .vertical
        $0.spacing = 4.0
        $0.setCustomSpacing(0, after: self.timeIndicatorView)
    }
    
    let titleLabel = UILabel(labelInit: {
        $0.font = Fonts.bold.size16
        $0.textColor =  Colors.dynamicSystemTitle
        $0.numberOfLines = 3
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.75
    })
    
    let usernameLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size12
        $0.textColor = Colors.darkGray
    })
    
    let detailLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size12
        $0.textColor = Colors.darkGray
    })
    
    let subredditImageView = UIImageView(imageViewInit: {
        $0.width(16)
        $0.height(16)
    })
    
    let subredditMaskView = UIView(viewInit: {
        $0.layer.masksToBounds = true
        $0.layer.cornerRadius = 8.0
    })
    
    let subredditLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size12
        $0.textColor = Colors.darkGray
    })
    
    let subscribeButton = UIButton(buttonInit: {
        $0.setImage(#imageLiteral(resourceName: "star-unselected"), for: .normal)
        $0.setImage(#imageLiteral(resourceName: "star-selected"), for: .selected)
    })
    
    lazy var subredditStackView = UIStackView([self.subredditMaskView, self.subredditLabel]) {
        $0.axis = .horizontal
        $0.spacing = 4.0
    }
    
    lazy var labelStackView = UIStackView([self.titleLabel, self.usernameLabel, self.detailLabel, self.subredditStackView, SpacerView.vertical]) {
        $0.axis = .vertical
        $0.spacing = 5.0
    }
    
    let mainStackViewSpacerView = SpacerView.horizontal
    
    lazy var mainStackView = UIStackView([self.thumbnailStackView, self.labelStackView, self.mainStackViewSpacerView, self.subscribeButton]) {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.setCustomSpacing(16, after: self.thumbnailStackView)
        $0.setCustomSpacing(4, after: self.mainStackViewSpacerView)
    }
    
    var timeIndicatorWidthConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.thumbnailMaskView.addSubview(self.thumbnailImageView)
        self.thumbnailImageView.edgesToSuperview()
        
        self.timeIndicatorWidthConstraint = self.timeIndicatorView.width(0)
        self.timeIndicatorView.height(2.0)
        
        self.contentView.addSubview(self.mainStackView)
        self.mainStackView.edgesToSuperview(insets: .uniform(14.0))
        
        self.contentView.addSubview(self.thumbnailAwardImageView)
        self.thumbnailAwardImageView.left(to: self.thumbnailMaskView, offset: -8)
        self.thumbnailAwardImageView.top(to: self.thumbnailMaskView, offset: -8)
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = Colors.dynamicCellSelected
        self.selectedBackgroundView = selectedBackgroundView
        
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(broadcast: Broadcast) {
        self.thumbnailImageView.kf.setImage(with: broadcast.stream.thumbnail, placeholder: #imageLiteral(resourceName: "thumbnail-default"))
        self.titleLabel.text = broadcast.post.title
        self.usernameLabel.text = "u/" + broadcast.broadcaster
        
        let viewers = broadcast.continuousWatchers.roundedDescription
        let upvotes = broadcast.upvotes.roundedDescription
        self.detailLabel.text = "\(viewers) viewers • \(upvotes) upvotes"
        
        self.subredditImageView.kf.setImage(with: broadcast.post.subreddit.styles.icon)
        self.subredditLabel.text = "r/" + broadcast.post.subreddit.name
        
        self.subredditMaskView.addSubview(self.subredditImageView)
        self.subredditImageView.edgesToSuperview()
        
        let totalTimeGranted = broadcast.broadcastTime + broadcast.estimatedRemainingTime
        self.timeIndicatorWidthConstraint?.constant = CGFloat(broadcast.broadcastTime/totalTimeGranted) * Constants.thumbnailWidth
        
        let userSubscriptions = SettingsService.shared.savedUserSubscriptions
        self.subscribeButton.isSelected = SettingsService.shared.isSubscribedTo(username: broadcast.broadcaster, fromUserSubscriptions: userSubscriptions)
        
        let largeAward = broadcast.post.awardings
            .sorted { $0.award.coinPrice > $1.award.coinPrice }
            .filter { $0.award.name == "Gold" || $0.award.name == "Platinum" || $0.award.name == "Argentium" }
            .first { $0.award.coinPrice >= 500 }
        
        if let largeAward = largeAward {
            self.thumbnailAwardImageView.isHidden = false
            self.thumbnailAwardImageView.kf.setImage(with: largeAward.award.icon128.url)
        }
        else {
            self.thumbnailAwardImageView.isHidden = true
        }
    }
}
