//
//  DonationButtonCell.swift
//  RPAN
//
//  Created by Erik Villegas on 7/16/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

class DonationButtonCell: UITableViewCell {
    let iconImageView = UIImageView(imageViewInit: {
        $0.image = #imageLiteral(resourceName: "kofi")
        $0.width(20)
        $0.height(20)
    })
    
    let titleLabel = UILabel(labelInit: {
        $0.text = "Support Me On Ko-fi!"
        $0.textAlignment = .center
        $0.font = Fonts.regular.size16
        $0.textColor = Colors.primaryOrange
        $0.numberOfLines = 2
        $0.width(164)
    })
    
    lazy var stackView = UIStackView([self.iconImageView, self.titleLabel]) {
        $0.axis = .horizontal
        $0.spacing = 8.0
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.stackView)
        self.stackView.centerInSuperview()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
