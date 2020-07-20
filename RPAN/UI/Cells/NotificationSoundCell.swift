//
//  NotificationSoundCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/19/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class NotificationSoundCell: UITableViewCell {
    let titleLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.centerYToSuperview()
        self.titleLabel.leftToSuperview(offset: 20)
        self.titleLabel.rightToSuperview(offset: 12)
        
        self.accessoryType = .checkmark
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
