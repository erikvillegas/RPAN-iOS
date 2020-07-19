//
//  TitleDetailCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class TitleDetailCell: UITableViewCell {
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
        
        self.contentView.addSubview(self.detailLabel)
        self.detailLabel.centerYToSuperview()
        self.detailLabel.rightToSuperview(offset: -20)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.centerYToSuperview()
        self.titleLabel.leftToSuperview(offset: 20)
        self.titleLabel.rightToLeft(of: self.detailLabel, offset: 12)
        
        self.accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
