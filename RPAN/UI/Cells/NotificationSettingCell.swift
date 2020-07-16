//
//  NotificationSettingCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class NotificationSettingCell: UITableViewCell {
    let titleLabel = UILabel(labelInit: {
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
    })
    
    let enabledSwitch = UISwitch(switchInit: {
        $0.onTintColor = Colors.primaryOrange
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.centerYToSuperview()
        self.titleLabel.leftToSuperview(offset: 20)
        
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
