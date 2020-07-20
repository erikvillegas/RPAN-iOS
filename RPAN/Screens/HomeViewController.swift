//
//  HomeViewController.swift
//  RPAN
//
//  Created by Erik Villegas on 7/7/20.
//  Copyright © 2020 Erik Villegas. All rights reserved.
//

import UIKit
import Foundation
import Kingfisher
import reddift
import Firebase
import FirebaseAuth
import SwiftMessages
import PromiseKit
import StoreKit
import SwiftDate

class HomeViewController: UIViewController {
    var broadcasts = [Broadcast]()
    var broadcastsFetchTimestamp = Date()
    
    let tableView = UITableView([BroadcastCell.self], style: .plain, {
        $0.rowHeight = UITableView.automaticDimension
        $0.tableFooterView = UIView()
        $0.backgroundColor = Colors.clear
    })
    
    let errorLabel = UILabel(labelInit: {
        $0.text = "No Broadcasts...\nPull down to refresh!"
        $0.font = Fonts.bold.size16
        $0.textColor = Colors.primaryOrange
        $0.isHidden = true
        $0.numberOfLines = 2
        $0.textAlignment = .center
    })
    
    let refreshControl = UIRefreshControl()
    
    init() {
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
        
        self.view.addSubview(self.errorLabel)
        self.errorLabel.centerInSuperview()
        
        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "app-logo"))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "account-icon"), style: .plain, target: self, action: #selector(accountButtonTapped))
        
        self.refreshControl.addTarget(self, action: #selector(fetchBroadcastsWithDelay), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.fetchBroadcasts(loadingMethod: .showIfEmpty(message: "Loading Broadcasts..."))
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForStaleBroadcasts), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Delay so the "New follower" banner does not conflict with the loading banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if LoginService.shared.loggedInUser != nil {
                self.importFollowers()
            }
            else {
                self.importExistingFavorites()
            }
        }
        
        AnalyticsService.shared.logScreenView(HomeViewController.self)
    }
    
    @objc func checkForStaleBroadcasts() {
        if Date().timeIntervalSince(self.broadcastsFetchTimestamp) > 60 {
            self.fetchBroadcasts(loadingMethod: .showImmediately(message: "Refreshing Broadcasts..."), delay: .milliseconds(1000))
        }
    }
    
    func fetchBroadcasts(loadingMethod: BroadcastLoadingIndicatorMethod, delay: DispatchTimeInterval = .seconds(0)) {
        switch loadingMethod {
        case .showIfEmpty(let message):
            if self.broadcasts.isEmpty {
                self.displayToast(message: message, theme: .info, duration: .indefinite(delay: 1.2, minimum: 0.2))
            }
        case .showImmediately(let message):
            self.displayToast(message: message, theme: .info)
        default:
            break
        }
        
        after(delay).then {
            return RedditAPI.shared.broadcasts()
        }.done { broadcasts in
            self.broadcasts = broadcasts
            self.displayBroadcasts()
            self.broadcastsFetchTimestamp = Date()
            self.errorLabel.isHidden = true
        }.catch { error in
            print(error)
            CrashService.shared.logError(error, message: "Fetch Broadcasts Failure")
            
            let message = "Reddit may be experiencing technical difficulties, try again?"
            self.showCustomActionAlert(title: "Hmmm", message: message, actionTitle: "Retry") { _ in
                self.fetchBroadcasts(loadingMethod: .showImmediately(message: "Retrying..."), delay: .milliseconds(500))
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.broadcasts.isEmpty {
                    self.errorLabel.isHidden = false
                }
            }
        }.finally {
            self.refreshControl.endRefreshing()
            SwiftMessages.sharedInstance.hideAll()
        }
    }
    
    @objc func fetchBroadcastsWithDelay() {
        self.fetchBroadcasts(loadingMethod: .hide, delay: .milliseconds(500))
    }
    
    func displayBroadcasts() {
        let userSubscriptions = SettingsService.shared.savedUserSubscriptions
        var broadcasts = self.broadcasts

        broadcasts.sort { b1, b2 -> Bool in
            let subscribedB1 = SettingsService.shared.isSubscribedTo(username: b1.broadcaster, fromUserSubscriptions: userSubscriptions)
            let subscribedB2 = SettingsService.shared.isSubscribedTo(username: b2.broadcaster, fromUserSubscriptions: userSubscriptions)
            
            // subscribed to both or neither
            if (subscribedB1 && subscribedB2) || (!subscribedB1 && !subscribedB2)  {
                return b1.continuousWatchers > b2.continuousWatchers
            }
            return subscribedB1
        }
        
        self.broadcasts = broadcasts
        
        self.tableView.reloadData()
    }
    
    @objc func accountButtonTapped() {
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.presentationController?.delegate = self
        self.present(settingsVC, animated: true, completion: nil)
        AnalyticsService.shared.logScreenView(SettingsViewController.self)
    }
    
    /// If we have no user subscriptions saved locally, check the server if we have any to persist locally
    func importExistingFavorites() {
        guard SettingsService.shared.savedUserSubscriptions.isEmpty else {
            return
        }
        
        SettingsService.shared.fetchUserSubscriptions().done { userSubscriptions in
            SettingsService.shared.savedUserSubscriptions = userSubscriptions
            
            if !userSubscriptions.isEmpty {
                self.tableView.reloadData()
            }
        }.catch { error in
            print(error)
            // todo: log
        }
    }
    
    func importFollowers() {
        let oldUserSubscriptions = SettingsService.shared.savedUserSubscriptions
        
        SettingsService.shared.importUserSubscriptions().done { userSubscriptions in
            var newUserSubscriptions = [UserSubscription]()
            
            for userSubscription in oldUserSubscriptions.difference(from: userSubscriptions) {
                if !oldUserSubscriptions.contains(userSubscription) {
                    newUserSubscriptions += userSubscription
                }
            }
            
            if !newUserSubscriptions.isEmpty {
                let view = MessageView.viewFromNib(layout: .statusLine)

                let usernames = newUserSubscriptions.map { "u/" + $0.username }.joined(separator: ", ")
                let plurality = newUserSubscriptions.count == 1 ? "follower" : "followers"
                
                view.configureContent(body: "Favorited new \(plurality): \(usernames)")
                view.configureTheme(.success)
                view.layoutMarginAdditions = .uniform(20)
                
                var config = SwiftMessages.Config()
                config.presentationContext = .viewController(self)

                SwiftMessages.show(config: config, view: view)
            }
        }.catch { error in
            // todo: log
        }
    }
    
    @objc func subscribeButtonTapped(starButton: UIButton) {
        starButton.isSelected = !starButton.isSelected
        let broadcast = self.broadcasts[starButton.tag]
        
        after(.milliseconds(350)).then { _ -> Guarantee<UNAuthorizationStatus> in
            if starButton.isSelected {
                return self.promptForNotifications(broadcast: broadcast)
            }
            else {
                return Guarantee.value(.notDetermined)
            }
        }.done { _ in
            if starButton.isSelected {
                let settingsService = SettingsService.shared
                settingsService.fetchUserProfile(username: broadcast.broadcaster).then { profile -> Promise<Void> in
                    let userSubscription = UserSubscription(
                        username: profile.username,
                        iconUrl: profile.iconUrl,
                        notify: true,
                        subredditBlacklist: [],
                        cooldown: false,
                        sound: Constants.DefaultNotificationSoundName)
                    return settingsService.persistFavorites(userSubscriptions: [userSubscription]).asVoid()
                }.catch { error in
                    CrashService.shared.logError(error, message: "Unable To Favorite")
                    self.displayToast(message: "Unable to favorite this user, please try again later!", theme: .error)
                    starButton.isSelected = !starButton.isSelected
                }
            }
            else {
                SettingsService.shared.removeFavorite(broadcaster: broadcast.broadcaster).catch { error in
                    CrashService.shared.logError(error, message: "Unable To Unfavorite")
                    self.displayToast(message: "Unable to unfavorite this user, please try again later!", theme: .error)
                    starButton.isSelected = !starButton.isSelected
                }
            }
        }
        
        if starButton.isSelected {
            AnalyticsService.shared.logEvent("Favorite User", metadata: ["broadcaster": broadcast.broadcaster])
        }
        else {
            AnalyticsService.shared.logEvent("Unfavorite User", metadata: ["broadcaster": broadcast.broadcaster])
        }
    }
    
    func promptForNotifications(broadcast: Broadcast) -> Guarantee<UNAuthorizationStatus> {
        guard !UserDefaultsService.shared.bool(forKey: .promptedForNotifications) else {
            return PushService.getAuthorizationStatus()
        }
        
        guard !UserDefaultsService.shared.bool(forKey: .seenNotificationPrePrompt) else {
            return PushService.getAuthorizationStatus()
        }
        
        AnalyticsService.shared.logEvent("Notification Pre-Prompt")
        
        return Guarantee { resolver in
            let message = "Would you like to enable notifications for u/\(broadcast.broadcaster) and other broadcasters you star when they start their stream?"
            self.showCustomActionsAlert(title: "Notifications", message: message, actionTitle: "Yes!", cancelTitle: "Maybe Later", actionHandler: { _ in
                UserDefaultsService.shared.set(true, forKey: .promptedForNotifications)
                UserDefaultsService.shared.set(true, forKey: .globalNotificationsOn)
                PushService.registerForRemoteNotifications()
                resolver(.authorized)
            }, cancelHandler: { _ in
                AnalyticsService.shared.logEvent("Notification Pre-Prompt Dismissed")
                resolver(.denied)
            })
        
            UserDefaultsService.shared.set(true, forKey: .seenNotificationPrePrompt)
        }
    }
    
    func openStoreAppStore(_ identifier: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        self.displayToast(message: "Loading App Store...", theme: .info, duration: .forever)
        
        let parameters = [ SKStoreProductParameterITunesItemIdentifier : identifier]
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) -> Void in
            if loaded {
                self?.present(storeViewController, animated: true, completion: {
                    SwiftMessages.sharedInstance.hideAll()
                })
            }
            else {
                CrashService.shared.logError(with: "App Store Load Failure")
                self?.showSimpleAlert(title: "Oops", message: "Unable to load the App Store, please ensure it is installed.")
                SwiftMessages.sharedInstance.hideAll()
            }
            
            if let error = error {
                CrashService.shared.logError(error, message: "App Store Open Failure")
                self?.showSimpleAlert(title: "Oops", message: "Unable to open the App Store, please ensure it is installed.")
            }
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.broadcasts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BroadcastCell.reuseId, for: indexPath) as? BroadcastCell else {
            return UITableViewCell()
        }
        
        cell.configure(broadcast: self.broadcasts[indexPath.row])
        cell.subscribeButton.addTarget(self, action: #selector(subscribeButtonTapped(starButton:)), for: .touchUpInside)
        cell.subscribeButton.tag = indexPath.row
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        // This is required when submitting to the App Store, otherwise they'll reject it since it requires the Reddit app to work
//        guard UserDefaultsService.shared.codableObject(type: AppConfig.self, forKey: .appConfig)?.s ?? false else {
//            AnalyticsService.shared.logEvent("Open Broadcast - Disabled")
//            return
//        }
        
        AnalyticsService.shared.logEvent("Open Broadcast - Enabled")
        
        let broadcast = self.broadcasts[indexPath.row]
        UIApplication.shared.open(broadcast.post.url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly : true]) { success in
            if !success {
                let message = "Install the Reddit app from the App Store to view this broadcast!"
                self.showCustomActionAlert(title: "Reddit App Required", message: message, actionTitle: "Install") { _ in
                    AnalyticsService.shared.logEvent("Open App Store For Reddit")
                    self.openStoreAppStore("1064216828")
                }
                
                AnalyticsService.shared.logEvent("Reddit Not Installed")
            }
        }
    }
}

extension HomeViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.displayBroadcasts()
    }
}

extension HomeViewController: SKStoreProductViewControllerDelegate {
    private func productViewControllerDidFinish(viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
