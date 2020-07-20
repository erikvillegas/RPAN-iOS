//
//  SubredditCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/20/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

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
