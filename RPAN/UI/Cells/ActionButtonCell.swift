//
//  ActionButtonCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class ActionButtonCell: UITableViewCell {
    let titleLabel = UILabel(labelInit: {
        $0.textAlignment = .center
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
        $0.numberOfLines = 2
    })
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.edgesToSuperview(insets: UIEdgeInsets.uniform(14.0))
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
