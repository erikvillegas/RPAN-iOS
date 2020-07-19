//
//  SoundsViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/19/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import AVFoundation

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


class SoundsViewController: UIViewController {
    let tableView = UITableView([NotificationSoundCell.self], style: .plain, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
    })
    
    let soundNames: [String]
    var selectedRow: Int
    
    init() {
        let resources = try! FileManager.default.contentsOfDirectory(atPath: Bundle.main.resourcePath!)
        self.soundNames = resources.filter { $0.hasSuffix(".caf") }.map { String($0.dropLast(4)) }
        
        self.selectedRow = 0 // TODO
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Notification Sound"
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        }
        else {
            self.view.backgroundColor = UIColor.white
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
    }
}

extension SoundsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.soundNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationSoundCell.reuseId, for: indexPath) as? NotificationSoundCell else {
            return UITableViewCell()
        }
        
        let soundName = self.soundNames[indexPath.row]
        let formattedSoundName = soundName.components(separatedBy: "-").joined(separator: " ").capitalized
        
        cell.titleLabel.text = formattedSoundName
        cell.accessoryType = self.selectedRow == indexPath.row ? .checkmark : .none
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension SoundsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedRow = indexPath.row
        self.tableView.reloadData()
        
        // TODO: persist the change
        
        if let soundURL = Bundle.main.url(forResource: self.soundNames[indexPath.row], withExtension: "caf") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound)
        }
    }
}
