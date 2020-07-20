//
//  SoundsViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/19/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import PromiseKit
import AVFoundation

protocol SoundsViewControllerDelegate: class {
    func updatedUserSubscriptionWithSoundSetting(userSubscription: UserSubscription)
}

class SoundsViewController: UIViewController {
    let tableView = UITableView([NotificationSoundCell.self], style: .plain, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
    })
    
    var userSubscription: UserSubscription
    let soundNames: [String]
    var selectedRow: Int
    var delegate: SoundsViewControllerDelegate?
    
    init(userSubscription: UserSubscription) {
        self.userSubscription = userSubscription
        
        let resources = try! FileManager.default.contentsOfDirectory(atPath: Bundle.main.resourcePath!)
        self.soundNames = resources.filter { $0.hasSuffix(".caf") }.map { String($0.dropLast(4)) }.sorted()
        
        let sound = self.userSubscription.sound == "default" ? "chord" : self.userSubscription.sound
        self.selectedRow = self.soundNames.firstIndex(of:  sound)!
        
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
        
        let paddedView = UIView()
        paddedView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 28)
        self.tableView.tableHeaderView = paddedView
        self.tableView.tableFooterView = paddedView
        
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
        
        let sound = self.soundNames[indexPath.row]
        
        let previousIndex = self.selectedRow
        self.selectedRow = indexPath.row
        self.tableView.reloadData()
        
        if let soundURL = Bundle.main.url(forResource: sound, withExtension: "caf") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound)
        }
        
        after(.milliseconds(750)).then {
            return SettingsService.shared.updateNotificationSoundSetting(userSubscription: self.userSubscription, sound: sound)
        }.done { _ in
            let updatedUserSubscription = self.userSubscription.withSound(sound: sound)
            self.userSubscription = updatedUserSubscription
            self.delegate?.updatedUserSubscriptionWithSoundSetting(userSubscription: updatedUserSubscription)
        }.catch { error in
            self.showSimpleAlert(title: "Oops", message: "There was a problem, please try again later")
            self.selectedRow = previousIndex
            self.tableView.reloadData()
        }
    }
}
