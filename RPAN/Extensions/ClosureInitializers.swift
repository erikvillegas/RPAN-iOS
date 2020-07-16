//
//  ClosureInitializers.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit

extension UIView {
    convenience init(viewInit: ((UIView) -> Void)? = nil) {
        self.init()
        viewInit?(self)
    }
}

extension UILabel {
    convenience init(labelInit: ((UILabel) -> Void)? = nil) {
        self.init()
        labelInit?(self)
    }

    convenience init(
        text: String? = nil,
        font: UIFont? = nil,
        color: UIColor? = nil,
        alignment: NSTextAlignment = .natural,
        numberOfLines: Int = 1,
        isHidden: Bool = false,
        labelInit: ((UILabel) -> Void)? = nil) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = color
        self.textAlignment = alignment
        self.numberOfLines = numberOfLines
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.5
        self.isHidden = isHidden
        labelInit?(self)
    }
}

extension UITextField {
    convenience init(fieldInit: ((UITextField) -> Void)? = nil) {
        self.init()
        fieldInit?(self)
    }
}

extension UITextView {
    convenience init(textViewInit: ((UITextView) -> Void)? = nil) {
        self.init()
        textViewInit?(self)
    }
}

extension UIButton {
    convenience init(buttonInit: ((UIButton) -> Void)? = nil) {
        self.init()
        buttonInit?(self)
    }
}

extension UIImageView {
    convenience init(imageViewInit: ((UIImageView) -> Void)? = nil) {
        self.init()
        imageViewInit?(self)
    }
}

extension UIPickerView {
    convenience init(pickerViewInit: ((UIPickerView) -> Void)? = nil) {
        self.init(frame: .zero)
        pickerViewInit?(self)
    }
}

extension UITableView {
    convenience init(_ cells: [UITableViewCell.Type] = [], style: UITableView.Style, _ tableViewInit: ((UITableView) -> Void)? = nil) {
        self.init(frame: CGRect.zero, style: style)
        for cell in cells {
            self.register(cell, forCellReuseIdentifier: cell.reuseId)
        }
        tableViewInit?(self)
    }
}

extension UIScrollView {
    convenience init(_ scrollViewInit: ((UIScrollView) -> Void)? = nil) {
        self.init()
        scrollViewInit?(self)
    }
}

extension UIStackView {
    convenience init(_ arrangedSubviews: [UIView]? = nil, stackViewInit: ((UIStackView) -> Void)? = nil) {
        if let arrangedSubviews = arrangedSubviews {
            self.init(arrangedSubviews: arrangedSubviews)
        }
        else {
            self.init()
        }

        stackViewInit?(self)
    }

    convenience init(_ stackViewInit: ((UIStackView) -> Void)? = nil) {
        self.init()
        stackViewInit?(self)
    }
}

extension UICollectionView {
    convenience init(layout: UICollectionViewLayout, collectionViewInit: ((UICollectionView) -> Void)?) {
        self.init(frame: .zero, collectionViewLayout: layout)
        collectionViewInit?(self)
    }
}

extension UICollectionViewFlowLayout {
    convenience init(collectionViewLayoutInit: ((UICollectionViewFlowLayout) -> Void)?) {
        self.init()
        collectionViewLayoutInit?(self)
    }
}

extension UISearchBar {
    convenience init(searchBarInit: ((UISearchBar) -> Void)? = nil) {
        self.init()
        searchBarInit?(self)
    }
}

extension UIActivityIndicatorView {
    convenience init(activityIndicatorViewInit: ((UIActivityIndicatorView) -> Void)? = nil) {
        self.init()
        activityIndicatorViewInit?(self)
    }
}

extension UISwitch {
    convenience init(switchInit: ((UISwitch) -> Void)? = nil) {
        self.init()
        switchInit?(self)
    }
}
