//
//  UserSubscriptionCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class UserSubscriptionCell: UITableViewCell {
    let avatarImageView = UIImageView(imageViewInit: {
        $0.width(26)
        $0.height(26)
        $0.layer.cornerRadius = 5
        $0.layer.masksToBounds = true
    })
    
    let titleLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
    })
    
    let detailLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size12
        $0.textAlignment = .right
        $0.textColor = Colors.mediumGray
        $0.width(50.0)
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.centerYToSuperview()
        self.avatarImageView.leftToSuperview(offset: 20)
        
        self.contentView.addSubview(self.detailLabel)
        self.detailLabel.centerYToSuperview()
        self.detailLabel.rightToSuperview(offset: -12)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.centerY(to: self.avatarImageView)
        self.titleLabel.leftToRight(of: self.avatarImageView, offset: 12)
        self.titleLabel.rightToLeft(of: self.detailLabel, offset: 12)
        
        self.accessoryType = .disclosureIndicator
    }
    
    func configure(userSubscription: UserSubscription) {
        self.titleLabel.text = "u/" + userSubscription.username
        self.detailLabel.text = userSubscription.notify ? "ON" : "OFF"
        
        if var components = URLComponents(string: userSubscription.iconUrl?.absoluteString ?? "") {
            components.query = nil

            self.avatarImageView.kf.setImage(with: components.url, placeholder: #imageLiteral(resourceName: "default-avatar"))
        }
        else {
            self.avatarImageView.image = #imageLiteral(resourceName: "default-avatar")
        }
        
        let globalNotificationsOn = UserDefaultsService.shared.bool(forKey: .globalNotificationsOn)
        self.titleLabel.alpha = globalNotificationsOn ? 1 : 0.5
        self.avatarImageView.alpha = globalNotificationsOn ? 1 : 0.5
        self.detailLabel.text = globalNotificationsOn ? self.detailLabel.text : "OFF"
        
        self.selectionStyle = globalNotificationsOn ? .default : .none
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
