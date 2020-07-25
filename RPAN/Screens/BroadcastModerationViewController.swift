//
//  BroadcastModerationViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/24/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import reddift
import PromiseKit

struct Comment {
    
}

class BroadcastModerationViewController: UIViewController {
    let broadcast: Broadcast
    var comments = [Comment]()
    
    let tableView = UITableView([BroadcastCell.self], style: .plain, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
    })
    
    let refreshControl = UIRefreshControl()
    
    init(broadcast: Broadcast) {
        self.broadcast = broadcast
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "account-icon"), style: .plain, target: self, action: #selector(accountButtonTapped))
        
        self.refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.refreshData()
        
        AnalyticsService.shared.logScreenView(BroadcastModerationViewController.self)
    }
    
    @objc func refreshData() {
        
    }
}

extension BroadcastModerationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.comments.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}

extension BroadcastModerationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
